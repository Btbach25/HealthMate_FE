import 'package:fe/data/mock_data/mock_health_data.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/models/health/health_overview.dart';
import 'package:fe/data/services/health_service.dart';
import 'package:fe/data/services/local_storage_service.dart';

/// [HealthService] giả lập cho chế độ DEMO.
///
/// Kế thừa service thật để giữ đúng kiểu dữ liệu trong object graph, nhưng
/// [getHealthOverview] được ghi đè hoàn toàn nên **không có request HTTP nào**.
///
/// Số liệu lấy từ `MockHealthData.overviewFor` — sửa ở đó để đổi chỉ số demo.
class MockHealthService extends HealthService {
  final LocalStorageService _storage;

  MockHealthService(this._storage) : super(_storage);

  @override
  Future<HealthOverview> getHealthOverview() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = await _storage.getUser();
    final userId = (user != null && user.isNotEmpty)
        ? user.id
        : MockUsers.demoUserId;
    return MockHealthData.overviewFor(userId);
  }
}
