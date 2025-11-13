import 'package:fe/data/models/details/metric_summary.dart';

class StatsPageData {
  final int totalReadings;
  final int totalTypes;
  final List<MetricSummary> metrics;

  StatsPageData({
    required this.totalReadings,
    required this.totalTypes,
    required this.metrics,
  });

  factory StatsPageData.empty() {
    return StatsPageData(
      totalReadings: 0,
      totalTypes: 0,
      metrics: [],
    );
  }
  
  StatsPageData copyWith({
    int? totalReadings,
    int? totalTypes,
    List<MetricSummary>? metrics,
  }) {
    return StatsPageData(
      totalReadings: totalReadings ?? this.totalReadings,
      totalTypes: totalTypes ?? this.totalTypes,
      metrics: metrics ?? this.metrics,
    );
  }
}