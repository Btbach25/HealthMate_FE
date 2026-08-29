import 'package:fe/data/models/health/health_overview.dart';
import 'package:fe/data/services/health_service.dart';

/// Cung cấp tổng quan chỉ số sức khoẻ ([HealthOverview]) cho UI.
///
/// Lớp bọc mỏng quanh [HealthService] — không bọc lỗi, lỗi được ném thẳng
/// lên caller.
///
/// Đăng ký implementation ở `lib/core/di/app_dependencies.dart`.
class HealthRepository {
  final HealthService _service;
  HealthRepository({required HealthService service}) : _service = service;

  Future<HealthOverview> getOverview() => _service.getHealthOverview();
}
