import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:fe/data/services/stats_service.dart';

/// Cổng vào của trang thống kê; uỷ quyền cho [StatsService].
///
/// Bọc mọi lỗi ngoài [ApiException] thành [UnknownException] kèm message
/// tiếng Việt để UI hiển thị được ngay.
///
/// Đổi nguồn dữ liệu bằng cách đăng ký một [StatsService] khác ở
/// `lib/core/di/app_dependencies.dart` (composition root).
class StatsRepository {
  final StatsService _statsService;

  StatsRepository({required StatsService statsService})
    : _statsService = statsService;

  Future<StatsPageData> getStatsPageData({String range = '7d'}) async {
    try {
      return await _statsService.getStatsPageData(range: range);
    } on ApiException {
      // ApiException đã có message hiển thị được -> giữ nguyên.
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải dữ liệu thống kê.',
        originalError: e,
      );
    }
  }

  Future<List<MetricChart>> getChartData({String range = '7d'}) async {
    try {
      return await _statsService.getChartData(range: range);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải dữ liệu biểu đồ.',
        originalError: e,
      );
    }
  }

  Future<List<MetricChart>> getChartDataForMember(
    String userId, {
    String range = '7d',
    List<String>? filterMetricTypes,
  }) async {
    try {
      return await _statsService.getChartDataForMember(
        userId,
        range: range,
        filterMetricTypes: filterMetricTypes,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải dữ liệu biểu đồ thành viên.',
        originalError: e,
      );
    }
  }
}
