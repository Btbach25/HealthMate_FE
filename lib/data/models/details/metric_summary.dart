import 'package:fe/data/enums/metric_status.dart';
import 'package:fe/core/utils/converter.dart';

class MetricSummary {
  final String id;
  final String title;
  final String unit;
  final String iconName;
  final double latestValue;
  final DateTime lastUpdate;
  final int readingCount;

  final double? trendPercentage;

  final MetricStatus status;

  final bool isIncreaseGood;

  MetricSummary({
    required this.id,
    required this.title,
    required this.unit,
    required this.iconName,
    required this.latestValue,
    required this.lastUpdate,
    required this.readingCount,
    this.trendPercentage,
    required this.status,
    required this.isIncreaseGood,
  });

  factory MetricSummary.fromJson(Map<String, dynamic> json) {
    return MetricSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      unit: json['unit'] as String,
      iconName: json['iconName'] as String,
      latestValue: (json['latestValue'] as num).toDouble(),
      lastUpdate: cvToDate(json['lastUpdate'] as String),
      readingCount: json['readingCount'] as int,
      trendPercentage: (json['trendPercentage'] as num?)?.toDouble(),
      status: MetricStatus.fromValue(json['status'] as String?),
      isIncreaseGood: json['isIncreaseGood'] as bool? ?? true,
    );
  }
}
