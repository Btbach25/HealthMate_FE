import 'package:fe/data/mock_data/mock_health_data.dart';
import 'package:fe/data/services/device_health_service.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// [DeviceHealthService] giả lập cho chế độ DEMO — **không đụng Health Connect**,
/// không xin quyền `activityRecognition`, không mở dialog cài đặt nào.
///
/// Trả về bộ [HealthDataPoint] dựng sẵn ở [MockHealthData.deviceDataPoints], đủ
/// đầu vào để `DeviceHealthCubit` tính được cả "Điểm sẵn sàng" lẫn "Mức độ căng
/// thẳng" — thiếu nhịp tim là cả hai thẻ đó sẽ trống.
class MockDeviceHealthService extends DeviceHealthService {
  MockDeviceHealthService();

  @override
  Future<DeviceHealthResult?> fetchAll({int hoursBack = 720}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final points = MockHealthData.deviceDataPoints;
    debugPrint(
      '[MockDeviceHealth] Trả ${points.length} điểm dữ liệu giả (chế độ DEMO)',
    );
    return DeviceHealthResult(
      dataPoints: points,
      totalSteps: MockHealthData.demoStepsToday,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<bool?> checkHCConnection() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Coi như đã kết nối để UI không hiện banner "chưa kết nối Health Connect".
    return true;
  }
}
