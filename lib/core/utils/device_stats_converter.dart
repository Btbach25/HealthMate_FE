import 'package:fe/data/enums/metric_status.dart';
import 'package:fe/data/models/details/chart_data_point.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/metric_summary.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';

/// Đổi dữ liệu thô từ Health Connect / Apple Health (`HealthDataPoint`) thành
/// model hiển thị của màn Chỉ số.
///
/// Đứng giữa package `health` và tầng UI, để widget không phải biết gì về
/// `HealthDataType`. Hai lối ra:
/// * [toStatsPageData] — thẻ tóm tắt (giá trị, xu hướng, trạng thái).
/// * [toChartData] — chuỗi điểm để vẽ biểu đồ đường.
///
/// Cả hai nhận cùng một danh sách điểm và cùng tham số `range`, nên gọi kèm
/// nhau với cùng giá trị `range` để số liệu và biểu đồ không lệch nhau.
///
/// ```dart
/// final points = await health.getHealthDataFromTypes(...);
/// final summary = DeviceStatsConverter.toStatsPageData(points, range: '7d');
/// final charts = DeviceStatsConverter.toChartData(points, range: '7d');
/// ```
///
/// Chỉ số nào không có dữ liệu trong khoảng thời gian sẽ bị BỎ HẲN khỏi kết
/// quả, chứ không trả về giá trị 0 — màn hình vì thế cần chịu được danh sách
/// rỗng hoặc thiếu chỉ số.
class DeviceStatsConverter {
  /// Mốc thời gian bắt đầu tính, theo `range`.
  ///
  /// Nhận `'24h'`, `'30d'`, còn lại đều rơi về 7 ngày — chuỗi sai chính tả sẽ
  /// âm thầm cho ra dữ liệu 7 ngày chứ không báo lỗi.
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

  /// Gộp các điểm đo thành thẻ tóm tắt cho màn Chỉ số.
  ///
  /// Thứ tự chỉ số trong kết quả là thứ tự cố định ở dưới (nhịp tim → bước
  /// chân → SpO2 → huyết áp → calo), chính là thứ tự hiển thị trên màn hình.
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
      'bước/ngày',
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

  /// Chỉ số kiểu "đo tại thời điểm": lấy giá trị MỚI NHẤT làm số hiển thị
  /// (nhịp tim, SpO2, huyết áp) — cộng dồn các giá trị này là vô nghĩa.
  ///
  /// `trendPercentage` so điểm mới nhất với điểm đầu khoảng, chỉ tính khi có
  /// từ 2 điểm và điểm đầu khác 0 (tránh chia cho 0); còn lại để `null` và UI
  /// sẽ ẩn phần xu hướng.
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

  /// Chỉ số kiểu "tích luỹ": cộng dồn rồi chia cho số NGÀY CÓ DỮ LIỆU để ra
  /// trung bình mỗi ngày (bước chân, calo).
  ///
  /// Cố ý chia theo số ngày thực sự có số liệu, không phải độ dài khoảng thời
  /// gian — ngày người dùng không đeo thiết bị mà tính vào mẫu số sẽ kéo tụt
  /// trung bình một cách vô lý.
  ///
  /// Không tính xu hướng cho nhóm này (`trendPercentage` luôn `null`) vì số
  /// hiển thị đã là một giá trị trung bình.
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
    final uniqueDays = pts.map((p) => DateTime(p.dateFrom.year, p.dateFrom.month, p.dateFrom.day)).toSet();
    final avgPerDay = uniqueDays.isEmpty ? total : total / uniqueDays.length;

    return MetricSummary(
      id: id,
      title: title,
      unit: unit,
      iconName: icon,
      latestValue: avgPerDay,
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

  /// Đổi điểm đo thành các chuỗi để vẽ biểu đồ đường.
  ///
  /// Điểm được sắp theo thời gian tăng dần và giữ nguyên độ phân giải gốc —
  /// không gộp theo ngày, nên khoảng `'30d'` của thiết bị đo dày có thể ra
  /// rất nhiều điểm; cần thì hãy giảm mẫu ở tầng vẽ.
  ///
  /// Màu đường được gán cứng theo từng chỉ số để màu giữ nguyên qua các lần
  /// tải lại.
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

  /// Ngưỡng tô màu cảnh báo cho thẻ chỉ số.
  ///
  /// Đây CHỈ là mốc tham khảo cho người lớn khoẻ mạnh lúc nghỉ, dùng để đổi
  /// màu thẻ — KHÔNG phải chẩn đoán y tế. Đừng dựa vào hàm này để đưa ra lời
  /// khuyên sức khoẻ trong app.
  ///
  /// Chỉ số không có ngưỡng (bước chân, calo) luôn trả `normal`.
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
