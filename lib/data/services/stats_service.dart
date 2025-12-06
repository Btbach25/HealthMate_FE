import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/stats_page_data.dart';

abstract class StatsService {
  Future<StatsPageData> getStatsPageData();

  Future<List<MetricChart>> getChartData();
}