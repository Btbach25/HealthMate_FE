import 'package:fe/data/mock_data/mock_health_data.dart';
import 'package:fe/data/services/device_health_service.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// [DeviceHealthService] giả lập cho chế độ DEMO — **không đụng Health Connect**,
/// không xin quyền `activityRecognition`, không mở dialog cài đặt nào.
///
/// Giới hạn có chủ ý: danh sách [HealthDataPoint] trả về rỗng vì model này
/// thuộc package `health` (cần uuid/nguồn/nền tảng thật). Số bước vẫn được trả
/// về nên thẻ hoạt động ở trang chủ có dữ liệu; các thẻ "điểm sẵn sàng" và
/// "căng thẳng" do `DeviceHealthCubit` tính từ data points nên sẽ trống trong
/// demo (chỉ số sức khoẻ chính vẫn hiển thị đầy đủ qua `MockHealthService`).
class MockDeviceHealthService extends DeviceHealthService {
  MockDeviceHealthService();

  @override
  Future<DeviceHealthResult?> fetchAll({int hoursBack = 720}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    debugPrint('[MockDeviceHealth] Trả dữ liệu thiết bị giả (chế độ DEMO)');
    return DeviceHealthResult(
      dataPoints: const <HealthDataPoint>[],
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
