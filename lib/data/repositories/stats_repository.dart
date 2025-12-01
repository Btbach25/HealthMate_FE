import 'package:fe/data/models/details/metric_chart.dart';
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

  Future<List<MetricChart>> getChartData() async {
    try {
      return await _statsService.getChartData();
    } catch (e) {
      print('Error in StatsRepository.getChartData: $e');
      rethrow;
    }
  }
}