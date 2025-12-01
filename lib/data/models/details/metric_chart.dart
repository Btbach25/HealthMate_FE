import 'dart:ui';

import 'package:fe/data/models/details/chart_data_point.dart';

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