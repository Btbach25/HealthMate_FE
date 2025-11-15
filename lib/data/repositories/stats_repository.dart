import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:fe/data/services/stats_service.dart';

class StatsRepository {
  final StatsService _statsService;

  StatsRepository({required StatsService statsService})
      : _statsService = statsService;

  Future<StatsPageData> getStatsPageData() async {
    try {
      final statsData = await _statsService.getStatsPageData();
      return statsData;
    } catch (e) {
      print('Error in StatsRepository.getStatsPageData: $e');
      rethrow;
    }
  }
}