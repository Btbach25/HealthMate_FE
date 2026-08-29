import 'dart:async';

import 'package:fe/data/mock_data/mock_health_data.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/services/health_ws_service.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// [HealthWsService] giả lập cho chế độ DEMO — **không mở WebSocket nào**.
///
/// - `connect` / `disconnect` / `subscribe*` / `send*`: no-op (chỉ ghi log).
/// - [watchStream]: phát sự kiện chỉ số giả mỗi [_tickInterval] để phần
///   "theo dõi realtime" trong dialog chỉ số của thành viên gia đình có dữ
///   liệu nhảy số như thật.
///
/// Giá trị phát ra lấy từ `MockHealthData.valueAt` (xác định, không random)
/// nên vẫn nằm trong khoảng sinh lý bình thường.
class MockHealthWsService extends HealthWsService {
  MockHealthWsService(LocalStorageService localStorage) : super(localStorage);

  /// Nhịp phát sự kiện giả.
  static const Duration _tickInterval = Duration(seconds: 5);

  /// Các chỉ số được "đẩy realtime" (đúng tên backend hỗ trợ).
  static const List<String> _metrics = [
    MockHealthData.heartRate,
    MockHealthData.stepsCount,
    MockHealthData.caloriesBurned,
    MockHealthData.bloodPressure,
    MockHealthData.spo2,
  ];

  StreamController<FamilyMetricWatchEvent> _controller =
      StreamController<FamilyMetricWatchEvent>.broadcast();
  Timer? _timer;
  int _tick = 0;

  @override
  Stream<FamilyMetricWatchEvent> get watchStream {
    if (_controller.isClosed) {
      _controller = StreamController<FamilyMetricWatchEvent>.broadcast();
    }
    _startTicker();
    return _controller.stream;
  }

  void _startTicker() {
    if (_timer != null) return;
    _timer = Timer.periodic(_tickInterval, (_) => _emitTick());
  }

  void _emitTick() {
    if (_controller.isClosed || !_controller.hasListener) return;
    _tick++;

    final metric = _metrics[_tick % _metrics.length];
    final profile = MockHealthData.profileOf(metric);
    final now = DateTime.now();

    for (final user in MockUsers.all) {
      _controller.add(
        FamilyMetricWatchEvent(
          ownerUserId: user.id,
          metricType: metric,
          value: MockHealthData.valueAt(
            profile,
            _tick,
            MockHealthData.seedOf(user.id),
          ),
          timestamp: now,
        ),
      );
    }
  }

  @override
  Future<void> connect() async {
    debugPrint('[MockHealthWs] Bỏ qua kết nối WebSocket (chế độ DEMO)');
  }

  @override
  Future<void> subscribeFamilyMemberMetrics({
    required String targetUserId,
    required String groupId,
    required List<String> metricTypeValues,
  }) async {
    // Mock phát sẵn sự kiện cho mọi thành viên nên không cần đăng ký gì.
    _startTicker();
  }

  @override
  Future<void> unsubscribeFamilyMemberMetrics({
    required String targetUserId,
    required String groupId,
    required List<String> metricTypeValues,
  }) async {
    // No-op: stream giả vẫn chạy cho tới khi disconnect().
  }

  @override
  Future<void> sendLatestMetrics(List<HealthDataPoint> points) async {
    // No-op: demo không gửi dữ liệu lên server.
  }

  @override
  Future<void> sendManualMetric(String metricType, double value) async {
    debugPrint('[MockHealthWs] Nhận chỉ số nhập tay (DEMO): $metricType=$value');
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
    debugPrint('[MockHealthWs] Đã dừng luồng chỉ số giả');
  }
}
