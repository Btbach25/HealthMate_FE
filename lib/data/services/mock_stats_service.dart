import 'package:fe/data/enums/metric_status.dart';
import 'package:fe/data/models/details/chart_data_point.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/metric_summary.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:fe/data/services/stats_service.dart';
import 'package:flutter/material.dart';

class MockStatsService implements StatsService {
  @override
  Future<StatsPageData> getStatsPageData() async {
    await Future.delayed(const Duration(milliseconds: 600));

    final lastUpdate = DateTime(2025, 11, 13);

    final metrics = [
      MetricSummary(
        id: '1',
        title: 'Số bước (bước)',
        unit: 'steps',
        iconName: 'steps',
        latestValue: 8888,
        lastUpdate: lastUpdate,
        readingCount: 30,
        trendPercentage: -15.1,
        status: MetricStatus.normal,
        isIncreaseGood: true,
      ),
      MetricSummary(
        id: '2',
        title: 'Huyết áp tâm thu (mmHg)',
        unit: 'mmHg',
        iconName: 'heart',
        latestValue: 127,
        lastUpdate: lastUpdate,
        readingCount: 60,
        trendPercentage: 9.5,
        status: MetricStatus.warning,
        isIncreaseGood: false,
      ),
      MetricSummary(
        id: '3',
        title: 'Huyết áp tâm trương (mmHg)',
        unit: 'mmHg',
        iconName: 'heart',
        latestValue: 90,
        lastUpdate: lastUpdate,
        readingCount: 60,
        trendPercentage: 3.4,
        status: MetricStatus.warning,
        isIncreaseGood: false,
      ),
      MetricSummary(
        id: '4',
        title: 'Nhịp tim (bpm)',
        unit: 'bpm',
        iconName: 'heart',
        latestValue: 88,
        lastUpdate: lastUpdate,
        readingCount: 60,
        trendPercentage: 6.0,
        status: MetricStatus.normal,
        isIncreaseGood: false,
      ),
      MetricSummary(
        id: '5',
        title: 'Cân nặng (kg)',
        unit: 'kg',
        iconName: 'weight',
        latestValue: 76,
        lastUpdate: lastUpdate,
        readingCount: 5,
        trendPercentage: 1.3,
        status: MetricStatus.normal,
        isIncreaseGood: false,
      ),
      MetricSummary(
        id: '6',
        title: 'Giờ ngủ (giờ)',
        unit: 'hours',
        iconName: 'sleep',
        latestValue: 7.8,
        lastUpdate: lastUpdate,
        readingCount: 30,
        trendPercentage: -2.5,
        status: MetricStatus.normal,
        isIncreaseGood: true,
      ),
    ];

    return StatsPageData(
      totalReadings: 245,
      totalTypes: 6,
      metrics: metrics,
    );
  }

  @override
  Future<List<MetricChart>> getChartData() async {
    await Future.delayed(const Duration(milliseconds: 900));

    final bloodPressurePoints = [
      ChartDataPoint(time: DateTime(2025, 10, 17), value: 120),
      ChartDataPoint(time: DateTime(2025, 10, 18), value: 130),
      ChartDataPoint(time: DateTime(2025, 10, 19), value: 128),
      ChartDataPoint(time: DateTime(2025, 10, 20), value: 116),
      ChartDataPoint(time: DateTime(2025, 10, 21), value: 138),
    ];

    final weightPoints = [
      ChartDataPoint(time: DateTime(2025, 10, 18), value: 73.8),
      ChartDataPoint(time: DateTime(2025, 10, 25), value: 73.0),
      ChartDataPoint(time: DateTime(2025, 11, 1), value: 73.0),
      ChartDataPoint(time: DateTime(2025, 11, 8), value: 73.9),
      ChartDataPoint(time: DateTime(2025, 11, 15), value: 73.0),
    ];

    return [
      MetricChart(
        id: 'bp_chart',
        title: 'Huyết áp theo thời gian',
        unit: 'mmHg',
        dataPointCount: 60,
        lineColor: Colors.red.shade400,
        points: bloodPressurePoints,
      ),
      MetricChart(
        id: 'weight_chart',
        title: 'Cân nặng theo thời gian',
        unit: 'kg',
        dataPointCount: 5,
        lineColor: Colors.green.shade600,
        points: weightPoints,
      ),
    ];
  }
}