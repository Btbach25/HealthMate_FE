import 'package:fe/data/models/health/health_overview.dart';
import 'package:fe/data/services/health_service.dart';

class HealthRepository {
  final HealthService _service;
  HealthRepository({required HealthService service}) : _service = service;

  Future<HealthOverview> getOverview() => _service.getHealthOverview();
}
