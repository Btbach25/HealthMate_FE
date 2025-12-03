import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:fe/data/services/stats_service.dart';

/// Repository for stats data operations
class StatsRepository {
  final StatsService _statsService;

  StatsRepository({required StatsService statsService})
      : _statsService = statsService;

  Future<StatsPageData> getStatsPageData() async {
    try {
      return await _statsService.getStatsPageData();
    } on ApiException {
      // Re-throw ApiException as-is (already has proper error messages)
      rethrow;
    } catch (e) {
      // Wrap unexpected errors
      throw UnknownException(
        message: 'Lỗi khi tải dữ liệu thống kê.',
        originalError: e,
      );
    }
  }
}