import 'package:fe/data/mock_data/mock_stats_data.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/data/services/stats_service.dart';

/// [StatsService] giả lập cho chế độ DEMO.
///
/// Toàn bộ số liệu sinh từ `MockStatsData` / `MockHealthData` — chuỗi mượt,
/// xác định (không random) và luôn kết thúc ở thời điểm hiện tại.
/// Hỗ trợ các khoảng thời gian `24h`, `7d`, `30d`, `90d`.
///
/// [localStorage] là tuỳ chọn: nếu có, biểu đồ của **chính mình** sẽ sinh theo
/// id user đang đăng nhập để mỗi tài khoản có chuỗi số riêng.
class MockStatsService implements StatsService {
  final LocalStorageService? _localStorage;

  MockStatsService({LocalStorageService? localStorage})
    : _localStorage = localStorage;

  Future<String> _currentUserId() async {
    final storage = _localStorage;
    if (storage != null) {
      final user = await storage.getUser();
      if (user != null && user.isNotEmpty) return user.id;
    }
    return MockUsers.demoUserId;
  }

  @override
  Future<StatsPageData> getStatsPageData({String range = '7d'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return MockStatsData.pageData(range: range, userId: await _currentUserId());
  }

  @override
  Future<List<MetricChart>> getChartData({String range = '7d'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return MockStatsData.charts(range: range, userId: await _currentUserId());
  }

  @override
  Future<List<MetricChart>> getChartDataForMember(
    String userId, {
    String range = '7d',
    List<String>? filterMetricTypes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return MockStatsData.charts(
      range: range,
      userId: userId.isEmpty ? await _currentUserId() : userId,
      filterTypes: filterMetricTypes,
    );
  }
}
