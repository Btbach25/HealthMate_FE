import 'package:fe/core/utils/converter.dart';
import 'package:fe/data/enums/metric_status.dart';

/// Thẻ tóm tắt một loại chỉ số trên trang Thống kê: giá trị mới nhất, xu
/// hướng và trạng thái đánh giá.
///
/// Được tổng hợp ở FE từ chuỗi điểm của `GET /metrics/charts` (xem
/// `ApiStatsService`) hoặc từ dữ liệu đọc trực tiếp trên thiết bị
/// (`DeviceStatsConverter`), nên không tương ứng 1-1 với một endpoint nào.
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
