import 'package:fe/data/enums/metric_status.dart';
import 'package:fe/data/mock_data/mock_health_data.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/models/details/chart_data_point.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/metric_summary.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:flutter/material.dart';

/// Dữ liệu cho màn hình **Thống kê** và mọi biểu đồ trong chế độ DEMO.
///
/// Chuỗi số được lấy từ [MockHealthData.series] nên biểu đồ mượt, có xu hướng
/// và giống nhau ở mọi lần mở app (không dùng `Random()`).
///
/// **Muốn đổi dữ liệu demo?**
/// - Đổi khoảng giá trị: sửa `MockHealthData.profiles`.
/// - Đổi màu đường biểu đồ: sửa [colorOf].
/// - Đổi ngưỡng cảnh báo (bình thường / cảnh báo / nguy hiểm): sửa [statusOf].
class MockStatsData {
  const MockStatsData._();

  /// Chuẩn hoá tên chỉ số của FE sang tên backend (`calories_burnt` là tên
  /// enum phía FE, backend dùng `calories_burned`).
  static String normalizeType(String type) =>
      type == 'calories_burnt' ? MockHealthData.caloriesBurned : type;

  /// Màu đường biểu đồ theo từng chỉ số.
  static Color colorOf(String type) {
    switch (normalizeType(type)) {
      case MockHealthData.heartRate:
        return Colors.red.shade400;
      case MockHealthData.stepsCount:
        return Colors.green.shade600;
      case MockHealthData.caloriesBurned:
        return Colors.orange.shade600;
      case MockHealthData.bloodPressure:
        return Colors.purple.shade400;
      case MockHealthData.spo2:
        return Colors.blue.shade400;
      case MockHealthData.weight:
        return Colors.teal.shade500;
      case MockHealthData.sleep:
        return Colors.indigo.shade400;
      case MockHealthData.temperature:
        return Colors.deepOrange.shade300;
      default:
        return Colors.grey;
    }
  }

  /// Trạng thái hiển thị (bình thường/cảnh báo/nguy hiểm) của một giá trị.
  static MetricStatus statusOf(String type, double value) {
    switch (normalizeType(type)) {
      case MockHealthData.heartRate:
        if (value < 60 || value > 100) return MetricStatus.warning;
        return MetricStatus.normal;
      case MockHealthData.spo2:
        if (value < 90) return MetricStatus.danger;
        if (value < 95) return MetricStatus.warning;
        return MetricStatus.normal;
      case MockHealthData.bloodPressure:
        if (value > 140) return MetricStatus.danger;
        if (value > 130) return MetricStatus.warning;
        return MetricStatus.normal;
      case MockHealthData.temperature:
        if (value > 37.5) return MetricStatus.warning;
        return MetricStatus.normal;
      default:
        return MetricStatus.normal;
    }
  }

  /// % thay đổi giữa điểm đầu và điểm cuối của chuỗi; `null` nếu không tính được.
  static double? trendOf(List<ChartDataPoint> points) {
    if (points.length < 2) return null;
    final first = points.first.value;
    if (first == 0) return null;
    final change = ((points.last.value - first) / first) * 100;
    return double.parse(change.toStringAsFixed(1));
  }

  /// Tóm tắt một chỉ số (thẻ trong tab "Gần đây"/"Tổng quan").
  static MetricSummary summaryOf({
    required String type,
    String range = '7d',
    String userId = MockUsers.demoUserId,
  }) {
    final profile = MockHealthData.profileOf(type);
    final points = MockHealthData.series(
      type: type,
      range: range,
      userId: userId,
    );
    final latest = points.last.value;

    return MetricSummary(
      id: normalizeType(type),
      title: profile.title,
      unit: profile.unit,
      iconName: profile.iconName,
      latestValue: latest,
      lastUpdate: points.last.time,
      readingCount: points.length,
      trendPercentage: trendOf(points),
      status: statusOf(type, latest),
      isIncreaseGood: profile.isIncreaseGood,
    );
  }

  /// Toàn bộ dữ liệu trang thống kê.
  static StatsPageData pageData({
    String range = '7d',
    String userId = MockUsers.demoUserId,
  }) {
    final metrics = MockHealthData.orderedTypes
        .map((t) => summaryOf(type: t, range: range, userId: userId))
        .toList();

    return StatsPageData(
      totalReadings: metrics.fold<int>(0, (sum, m) => sum + m.readingCount),
      totalTypes: metrics.length,
      metrics: metrics,
    );
  }

  /// Biểu đồ của một chỉ số.
  static MetricChart chartOf({
    required String type,
    String range = '7d',
    String userId = MockUsers.demoUserId,
  }) {
    final profile = MockHealthData.profileOf(type);
    final points = MockHealthData.series(
      type: type,
      range: range,
      userId: userId,
    );

    return MetricChart(
      id: normalizeType(type),
      title: profile.title,
      unit: profile.unit,
      dataPointCount: points.length,
      lineColor: colorOf(type),
      points: points,
    );
  }

  /// Danh sách biểu đồ.
  ///
  /// [filterTypes] (nếu có) là danh sách tên chỉ số cần lấy — dùng khi xem chỉ
  /// số của một thành viên gia đình (chỉ những chỉ số họ chia sẻ).
  static List<MetricChart> charts({
    String range = '7d',
    String userId = MockUsers.demoUserId,
    List<String>? filterTypes,
  }) {
    final types = filterTypes == null
        ? MockHealthData.orderedTypes
        : filterTypes.map(normalizeType).toSet().toList();

    return types
        .where((t) => MockHealthData.profiles.containsKey(t))
        .map((t) => chartOf(type: t, range: range, userId: userId))
        .toList();
  }
}
