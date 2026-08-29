import 'dart:async';
import 'dart:convert';

import 'package:fe/core/config/app_config.dart';
import 'package:fe/core/utils/metric_selection_helper.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Sự kiện chỉ số realtime khi đang subscribe theo thành viên nhóm (payload từ realtime-service).
class FamilyMetricWatchEvent {
  final String ownerUserId;
  final String metricType;
  final double value;
  final DateTime timestamp;

  const FamilyMetricWatchEvent({
    required this.ownerUserId,
    required this.metricType,
    required this.value,
    required this.timestamp,
  });
}

/// Service upload dữ liệu sức khỏe lên BE qua WebSocket.
/// Giữ kết nối persistent, tự reconnect khi bị đứt.
class HealthWsService {
  final LocalStorageService _localStorage;
  final Future<String?> Function()? _onRefresh;

  HealthWsService(this._localStorage, {Future<String?> Function()? onRefresh})
      : _onRefresh = onRefresh;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  bool _connected = false;
  String? _userId;

  final StreamController<FamilyMetricWatchEvent> _watchController =
      StreamController<FamilyMetricWatchEvent>.broadcast();

  /// Luồng chỉ số đã lọc (mọi target); UI tự lọc theo `ownerUserId`.
  Stream<FamilyMetricWatchEvent> get watchStream => _watchController.stream;

  /// BE realtime-service giới hạn ~512 byte / tin nhắn client → gửi subscribe theo lô nhỏ.
  static const int _maxSubscribeItemsPerMessage = 2;

  String get _wsBaseUrl => AppConfig.wsBaseUrl;

  static const Map<HealthDataType, String> _metricMap = {
    HealthDataType.HEART_RATE: 'heart_rate',
    HealthDataType.RESTING_HEART_RATE: 'heart_rate',
    HealthDataType.STEPS: 'steps_count',
    HealthDataType.ACTIVE_ENERGY_BURNED: 'calories_burned',
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC: 'blood_pressure',
    HealthDataType.BLOOD_OXYGEN: 'spo2',
    HealthDataType.WEIGHT: 'weight',
  };

  double? _extractNumeric(HealthDataPoint point) {
    final v = point.value;
    if (v is NumericHealthValue) return v.numericValue.toDouble();
    return null;
  }

  String _formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final abs = offset.abs();
    final hours = abs.inHours.toString().padLeft(2, '0');
    final minutes = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  /// Kết nối WS. Gọi một lần khi bắt đầu sync.
  Future<void> connect() async {
    if (kIsWeb || _connected) return;

    final user = await _localStorage.getUser();
    if (user == null) return;
    _userId = user.id;

    // Thử kết nối với token hiện tại
    String? token = await _localStorage.getAccessToken();
    if (token == null) return;

    await _tryConnect(token);

    // Nếu thất bại, thử refresh token và kết nối lại
    if (!_connected && _onRefresh != null) {
      final newToken = await _onRefresh();
      if (newToken != null) await _tryConnect(newToken);
    }
  }

  Future<void> _tryConnect(String token) async {
    try {
      await _socketSubscription?.cancel();
      _socketSubscription = null;

      // Dart's Uri không biết default port cho scheme ws/wss → set tường minh,
      // tránh URI bị :0 khiến WebSocket.connect đi sai cổng.
      final base = Uri.parse(_wsBaseUrl);
      final port = base.hasPort ? base.port : (base.scheme == 'wss' ? 443 : 80);
      final uri = Uri(
        scheme: base.scheme,
        host: base.host,
        port: port,
        path: '/ws',
        queryParameters: {'token': token},
      );
      // URL hiển thị không kèm token (bảo mật) và có port đúng (không phải :0).
      final displayUrl = '${base.scheme}://${base.host}:$port/ws';
      debugPrint('[HealthWs] → connecting $displayUrl');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;
      debugPrint('[HealthWs] ✓ Connected $displayUrl');
      if (kDebugMode) {
        final now = DateTime.now();
        debugPrint(
          '[HealthWs] Device timezone: '
          'name=${now.timeZoneName}, '
          'offset=${_formatOffset(now.timeZoneOffset)}, '
          'localNow=${now.toIso8601String()}',
        );
      }

      _socketSubscription = _channel!.stream.listen(
        _handleIncoming,
        onError: (_) => _onDisconnected(),
        onDone: _onDisconnected,
      );
    } catch (e) {
      _connected = false;
      _channel = null;
      final reason = e.toString().contains('not upgraded')
          ? 'server không upgrade lên WebSocket (nginx thiếu Upgrade/Connection header cho /ws)'
          : e.toString().replaceAll('WebSocketChannelException: ', '');
      debugPrint('[HealthWs] ✗ Connect failed → $reason');
    }
  }

  void _handleIncoming(dynamic data) {
    if (data is! String) return;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type'] as String?;
      if (type != 'metric') return;
      final rawPayload = decoded['payload'];
      if (rawPayload is! Map<String, dynamic>) return;
      final owner = rawPayload['user_id'] as String?;
      final metric = rawPayload['metric_type'] as String?;
      final value = rawPayload['value'];
      final tsRaw = rawPayload['timestamp'];
      if (owner == null || metric == null || value is! num) return;
      DateTime ts;
      if (tsRaw is String) {
        ts = DateTime.tryParse(tsRaw) ?? DateTime.now().toUtc();
      } else {
        ts = DateTime.now().toUtc();
      }
      _watchController.add(
        FamilyMetricWatchEvent(
          ownerUserId: owner,
          metricType: metric,
          value: value.toDouble(),
          timestamp: ts,
        ),
      );
    } catch (e) {
      debugPrint('[HealthWs] Parse incoming: $e');
    }
  }

  void _onDisconnected() {
    _connected = false;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _channel = null;
    debugPrint('[HealthWs] Disconnected');
  }

  /// Subscribe nhiều chỉ số của một thành viên trong nhóm (đã kiểm tra quyền phía BE).
  Future<void> subscribeFamilyMemberMetrics({
    required String targetUserId,
    required String groupId,
    required List<String> metricTypeValues,
  }) async {
    if (kIsWeb) return;
    if (!_connected) await connect();
    if (!_connected || _channel == null) return;

    final names = MetricSelectionHelper.filterMetricTypesForBackend(
      metricTypeValues,
    );
    if (names.isEmpty) return;

    for (var i = 0; i < names.length; i += _maxSubscribeItemsPerMessage) {
      final end = (i + _maxSubscribeItemsPerMessage > names.length)
          ? names.length
          : i + _maxSubscribeItemsPerMessage;
      final batch = names.sublist(i, end);
      final items = batch
          .map(
            (m) => {
              'target_user_id': targetUserId,
              'metric_type': m,
              'group_id': groupId,
            },
          )
          .toList();
      try {
        _channel!.sink.add(jsonEncode({'action': 'subscribe', 'items': items}));
      } catch (e) {
        debugPrint('[HealthWs] subscribe send error: $e');
        _onDisconnected();
        break;
      }
    }
  }

  Future<void> unsubscribeFamilyMemberMetrics({
    required String targetUserId,
    required String groupId,
    required List<String> metricTypeValues,
  }) async {
    if (kIsWeb) return;
    if (!_connected || _channel == null) return;

    final names = MetricSelectionHelper.filterMetricTypesForBackend(
      metricTypeValues,
    );
    if (names.isEmpty) return;

    for (var i = 0; i < names.length; i += _maxSubscribeItemsPerMessage) {
      final end = (i + _maxSubscribeItemsPerMessage > names.length)
          ? names.length
          : i + _maxSubscribeItemsPerMessage;
      final batch = names.sublist(i, end);
      final items = batch
          .map(
            (m) => {
              'target_user_id': targetUserId,
              'metric_type': m,
              'group_id': groupId,
            },
          )
          .toList();
      try {
        _channel!.sink.add(
          jsonEncode({'action': 'unsubscribe', 'items': items}),
        );
      } catch (e) {
        debugPrint('[HealthWs] unsubscribe send error: $e');
        _onDisconnected();
        break;
      }
    }
  }

  /// Gửi các metric mới nhất từ danh sách data points.
  /// Nếu chưa kết nối thì tự connect lại.
  Future<void> sendLatestMetrics(List<HealthDataPoint> points) async {
    if (kIsWeb) return;
    if (!_connected) await connect();
    if (!_connected || _channel == null || _userId == null) return;

    // Lấy điểm mới nhất cho mỗi metric type
    final latest = <String, HealthDataPoint>{};
    for (final point in points) {
      final metricType = _metricMap[point.type];
      if (metricType == null) continue;
      final existing = latest[metricType];
      if (existing == null || point.dateFrom.isAfter(existing.dateFrom)) {
        latest[metricType] = point;
      }
    }

    if (latest.isEmpty) return;

    for (final entry in latest.entries) {
      final value = _extractNumeric(entry.value);
      if (value == null) continue;
      try {
        _channel!.sink.add(jsonEncode({
          'user_id': _userId,
          'metric_type': entry.key,
          'value': value,
          'timestamp': entry.value.dateFrom.toUtc().toIso8601String(),
        }));
      } catch (e) {
        debugPrint('[HealthWs] Send error: $e');
        _onDisconnected();
        break;
      }
    }
  }

  /// Gửi một chỉ số nhập tay từ user lên BE qua WebSocket.
  Future<void> sendManualMetric(String metricType, double value) async {
    if (kIsWeb) return;
    if (!_connected) await connect();
    if (!_connected || _channel == null || _userId == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'user_id': _userId,
        'metric_type': metricType,
        'value': value,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));
      debugPrint('[HealthWs] Manual metric sent: $metricType=$value');
    } catch (e) {
      debugPrint('[HealthWs] Manual send error: $e');
      _onDisconnected();
    }
  }

  Future<void> disconnect() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _channel?.sink.close();
    _connected = false;
    _channel = null;
  }
}
