import 'dart:async';
import 'dart:convert';
import 'package:fe/core/config/api_base_url.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fe/data/services/local_storage_service.dart';

/// Service upload dữ liệu sức khỏe lên BE qua WebSocket.
/// Giữ kết nối persistent, tự reconnect khi bị đứt.
class HealthWsService {
  final LocalStorageService _localStorage;
  final Future<String?> Function()? _onRefresh;

  HealthWsService(this._localStorage, {Future<String?> Function()? onRefresh})
      : _onRefresh = onRefresh;

  WebSocketChannel? _channel;
  bool _connected = false;
  String? _userId;

  String get _wsBaseUrl {
    final httpBase = resolveApiBaseUrl();
    return httpBase
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
  }

  static const Map<HealthDataType, String> _metricMap = {
    HealthDataType.HEART_RATE: 'heart_rate',
    HealthDataType.RESTING_HEART_RATE: 'heart_rate',
    HealthDataType.STEPS: 'steps_count',
    HealthDataType.ACTIVE_ENERGY_BURNED: 'calories_burned',
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC: 'blood_pressure',
    HealthDataType.BLOOD_OXYGEN: 'spo2',
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
      final uri = Uri.parse('$_wsBaseUrl/ws?token=$token');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;
      debugPrint('[HealthWs] Connected');
      if (kDebugMode) {
        final now = DateTime.now();
        debugPrint(
          '[HealthWs] Device timezone: '
          'name=${now.timeZoneName}, '
          'offset=${_formatOffset(now.timeZoneOffset)}, '
          'localNow=${now.toIso8601String()}',
        );
      }

      _channel!.stream.listen(
        (_) {},
        onError: (_) => _onDisconnected(),
        onDone: _onDisconnected,
      );
    } catch (e) {
      _connected = false;
      _channel = null;
      debugPrint('[HealthWs] Connect failed: $e');
    }
  }

  void _onDisconnected() {
    _connected = false;
    _channel = null;
    debugPrint('[HealthWs] Disconnected');
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

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _connected = false;
    _channel = null;
  }
}
