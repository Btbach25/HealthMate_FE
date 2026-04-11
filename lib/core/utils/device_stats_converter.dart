import 'package:fe/data/enums/metric_status.dart';
import 'package:fe/data/models/details/chart_data_point.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/metric_summary.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';

class DeviceStatsConverter {
  static DateTime _cutoff(String range) {
    final now = DateTime.now();
    switch (range) {
      case '24h':
        return now.subtract(const Duration(hours: 24));
      case '30d':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  static StatsPageData toStatsPageData(
    List<HealthDataPoint> points, {
    String range = '7d',
  }) {
    final cutoff = _cutoff(range);
    final filtered = points.where((p) => p.dateFrom.isAfter(cutoff)).toList();
    final metrics = <MetricSummary>[];

    final hr = _buildLatestMetric(
      filtered,
      HealthDataType.HEART_RATE,
      'heart_rate',
      'Nhịp tim',
      'bpm',
      'heart',
      false,
    );
    if (hr != null) metrics.add(hr);

    final steps = _buildSumMetric(
      filtered,
      HealthDataType.STEPS,
      'steps_count',
      'Số bước chân',
      'bước',
      'steps',
      true,
    );
    if (steps != null) metrics.add(steps);

    final spo2 = _buildLatestMetric(
      filtered,
      HealthDataType.BLOOD_OXYGEN,
      'spo2',
      'SpO2',
      '%',
      'heart',
      true,
    );
    if (spo2 != null) metrics.add(spo2);

    final bp = _buildLatestMetric(
      filtered,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      'blood_pressure',
      'Huyết áp tâm thu',
      'mmHg',
      'heart',
      false,
    );
    if (bp != null) metrics.add(bp);

    final cal = _buildSumMetric(
      filtered,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      'calories_burned',
      'Calories tiêu thụ',
      'kcal',
      'heart',
      true,
    );
    if (cal != null) metrics.add(cal);

    return StatsPageData(
      totalReadings: metrics.fold(0, (s, m) => s + m.readingCount),
      totalTypes: metrics.length,
      metrics: metrics,
    );
  }

  /// Dùng giá trị mới nhất (heart_rate, spo2, blood_pressure).
  static MetricSummary? _buildLatestMetric(
    List<HealthDataPoint> all,
    HealthDataType type,
    String id,
    String title,
    String unit,
    String icon,
    bool isIncreaseGood,
  ) {
    final pts = _sorted(all, type);
    if (pts.isEmpty) return null;

    final values = pts.map(_numericValue).whereType<double>().toList();
    if (values.isEmpty) return null;

    final latest = values.last;
    double? trend;
    if (values.length >= 2 && values.first != 0) {
      trend = ((latest - values.first) / values.first) * 100;
    }

    return MetricSummary(
      id: id,
      title: title,
      unit: unit,
      iconName: icon,
      latestValue: latest,
      lastUpdate: pts.last.dateFrom,
      readingCount: values.length,
      trendPercentage: trend,
      status: _status(id, latest),
      isIncreaseGood: isIncreaseGood,
    );
  }

  /// Dùng tổng (steps, calories).
  static MetricSummary? _buildSumMetric(
    List<HealthDataPoint> all,
    HealthDataType type,
    String id,
    String title,
    String unit,
    String icon,
    bool isIncreaseGood,
  ) {
    final pts = _sorted(all, type);
    if (pts.isEmpty) return null;

    double total = 0;
    for (final p in pts) {
      total += _numericValue(p) ?? 0;
    }

    return MetricSummary(
      id: id,
      title: title,
      unit: unit,
      iconName: icon,
      latestValue: total,
      lastUpdate: pts.last.dateFrom,
      readingCount: pts.length,
      trendPercentage: null,
      status: MetricStatus.normal,
      isIncreaseGood: isIncreaseGood,
    );
  }

  static List<HealthDataPoint> _sorted(
    List<HealthDataPoint> all,
    HealthDataType type,
  ) =>
      all.where((p) => p.type == type).toList()
        ..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

  static double? _numericValue(HealthDataPoint p) {
    final v = p.value;
    if (v is NumericHealthValue) return v.numericValue.toDouble();
    return null;
  }

  static List<MetricChart> toChartData(
    List<HealthDataPoint> points, {
    String range = '7d',
  }) {
    final cutoff = _cutoff(range);
    final filtered = points.where((p) => p.dateFrom.isAfter(cutoff)).toList();
    final charts = <MetricChart>[];

    final hrPts = _chartPoints(filtered, HealthDataType.HEART_RATE);
    if (hrPts.isNotEmpty) {
      charts.add(
        MetricChart(
          id: 'heart_rate',
          title: 'Nhịp tim',
          unit: 'bpm',
          lineColor: Colors.red.shade400,
          dataPointCount: hrPts.length,
          points: hrPts,
        ),
      );
    }

    final stepPts = _chartPoints(filtered, HealthDataType.STEPS);
    if (stepPts.isNotEmpty) {
      charts.add(
        MetricChart(
          id: 'steps_count',
          title: 'Số bước chân',
          unit: 'bước',
          lineColor: Colors.green.shade600,
          dataPointCount: stepPts.length,
          points: stepPts,
        ),
      );
    }

    final spo2Pts = _chartPoints(filtered, HealthDataType.BLOOD_OXYGEN);
    if (spo2Pts.isNotEmpty) {
      charts.add(
        MetricChart(
          id: 'spo2',
          title: 'SpO2',
          unit: '%',
          lineColor: Colors.blue.shade400,
          dataPointCount: spo2Pts.length,
          points: spo2Pts,
        ),
      );
    }

    final bpPts = _chartPoints(
      filtered,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    );
    if (bpPts.isNotEmpty) {
      charts.add(
        MetricChart(
          id: 'blood_pressure',
          title: 'Huyết áp tâm thu',
          unit: 'mmHg',
          lineColor: Colors.purple.shade400,
          dataPointCount: bpPts.length,
          points: bpPts,
        ),
      );
    }

    final calPts = _chartPoints(filtered, HealthDataType.ACTIVE_ENERGY_BURNED);
    if (calPts.isNotEmpty) {
      charts.add(
        MetricChart(
          id: 'calories_burned',
          title: 'Calories tiêu thụ',
          unit: 'kcal',
          lineColor: Colors.orange.shade600,
          dataPointCount: calPts.length,
          points: calPts,
        ),
      );
    }

    return charts;
  }

  static List<ChartDataPoint> _chartPoints(
    List<HealthDataPoint> all,
    HealthDataType type,
  ) {
    return _sorted(all, type)
        .map((p) {
          final v = _numericValue(p);
          if (v == null) return null;
          return ChartDataPoint(time: p.dateFrom, value: v);
        })
        .whereType<ChartDataPoint>()
        .toList();
  }

  static MetricStatus _status(String id, double v) {
    switch (id) {
      case 'heart_rate':
        if (v < 60 || v > 100) return MetricStatus.warning;
        return MetricStatus.normal;
      case 'spo2':
        if (v < 90) return MetricStatus.danger;
        if (v < 95) return MetricStatus.warning;
        return MetricStatus.normal;
      case 'blood_pressure':
        if (v > 140) return MetricStatus.danger;
        if (v > 120) return MetricStatus.warning;
        return MetricStatus.normal;
      default:
        return MetricStatus.normal;
    }
  }
}
