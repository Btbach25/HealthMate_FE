import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/stats_page_data.dart';

abstract class StatsService {
  Future<StatsPageData> getStatsPageData({String range = '7d'});

  Future<List<MetricChart>> getChartData({String range = '7d'});

  /// Lấy chart data cho một thành viên cụ thể (dùng trong dialog xem chỉ số gia đình).
  /// [filterMetricTypes] nếu không null, chỉ lấy các metric type có trong list.
  Future<List<MetricChart>> getChartDataForMember(
    String userId, {
    String range = '7d',
    List<String>? filterMetricTypes,
  });
}
