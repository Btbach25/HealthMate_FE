import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:health/health.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fe/data/services/local_storage_service.dart';

/// Service upload dữ liệu sức khỏe lên BE qua WebSocket.
/// BE endpoint: ws://host/ws?token=access_token
/// Mỗi lần gọi uploadDataPoints sẽ mở kết nối, gửi dữ liệu rồi đóng.
class HealthWsService {
  final LocalStorageService _localStorage;

  HealthWsService(this._localStorage);

  String get _wsBaseUrl {
    final envUrl = dotenv.env['BASE_URL'];
    final httpBase = (envUrl != null && envUrl.isNotEmpty)
        ? envUrl
        : 'http://localhost:8080';
    // http → ws, https → wss
    return httpBase
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
  }

  /// Map từ HealthDataType của device → metric_type mà BE chấp nhận.
  static const Map<HealthDataType, String> _metricMap = {
    HealthDataType.HEART_RATE: 'heart_rate',
    HealthDataType.RESTING_HEART_RATE: 'heart_rate',
    HealthDataType.STEPS: 'steps_count',
    HealthDataType.ACTIVE_ENERGY_BURNED: 'calories_burned',
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC: 'blood_pressure',
    HealthDataType.BLOOD_OXYGEN: 'spo2',
  };

  double? _extractNumericValue(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) return value.numericValue.toDouble();
    return null;
  }

  /// Upload danh sách data points lên BE qua WebSocket.
  /// Chỉ gửi các metric type mà BE hỗ trợ.
  Future<void> uploadDataPoints(List<HealthDataPoint> points) async {
    // Device health không có trên web
    if (kIsWeb) return;

    final token = await _localStorage.getAccessToken();
    if (token == null) {
      debugPrint('[HealthWs] Chưa đăng nhập, bỏ qua upload');
      return;
    }

    final user = await _localStorage.getUser();
    if (user == null) {
      debugPrint('[HealthWs] Không có thông tin user');
      return;
    }

    final supported =
        points.where((p) => _metricMap.containsKey(p.type)).toList();
    if (supported.isEmpty) {
      debugPrint('[HealthWs] Không có metric nào để upload');
      return;
    }

    WebSocketChannel? channel;
    try {
      final uri = Uri.parse('$_wsBaseUrl/ws?token=$token');
      debugPrint('[HealthWs] Connecting to $uri');
      channel = WebSocketChannel.connect(uri);
      await channel.ready;
      debugPrint('[HealthWs] Connected. Uploading ${supported.length} points...');

      int sent = 0;
      for (final point in supported) {
        final metricType = _metricMap[point.type]!;
        final value = _extractNumericValue(point);
        if (value == null) continue;

        channel.sink.add(jsonEncode({
          'user_id': user.id,
          'metric_type': metricType,
          'value': value,
          'timestamp': point.dateFrom.toUtc().toIso8601String(),
        }));
        sent++;
      }

      debugPrint('[HealthWs] Sent $sent metric points');
    } catch (e) {
      debugPrint('[HealthWs] Upload error: $e');
    } finally {
      await channel?.sink.close();
    }
  }
}
