import 'dart:ui';

import 'package:fe/data/models/details/chart_data_point.dart';

/// Toàn bộ dữ liệu để vẽ một biểu đồ của một loại chỉ số.
///
/// Gom kết quả `GET /metrics/charts?metric_type=...` lại và bổ sung phần
/// trình bày ([title], [unit], [lineColor]) do FE tự quyết định — backend
/// chỉ trả về chuỗi `{timestamp, value}`.
class MetricChart {
  final String id;
  final String title;
  final String unit;
  final int dataPointCount;
  final Color lineColor;
  final List<ChartDataPoint> points;

  MetricChart({
    required this.id,
    required this.title,
    required this.unit,
    required this.dataPointCount,
    required this.lineColor,
    required this.points,
  });
}
