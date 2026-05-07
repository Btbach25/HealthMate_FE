import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/ui/metric_option.dart';
import 'package:flutter/material.dart';

/// Helper class to generate available metric options for UI
class MetricHelper {
  /// All available metric options with labels and icons
  /// Reusable constant to avoid defining in multiple places
  static const List<MetricOption> availableMetrics = [
    MetricOption(
      type: MetricType.heartRate,
      label: 'Nhịp tim',
      icon: AppIcons.heart,
    ),
    MetricOption(
      type: MetricType.bloodPressure,
      label: 'Huyết áp',
      icon: AppIcons.bloodPressure,
    ),
    MetricOption(
      type: MetricType.spo2,
      label: 'SpO2',
      icon: AppIcons.spo2,
    ),
    MetricOption(
      type: MetricType.weight,
      label: 'Cân nặng',
      icon: AppIcons.weight,
    ),
    MetricOption(
      type: MetricType.temperature,
      label: 'Nhiệt độ',
      icon: AppIcons.temperature,
    ),
    MetricOption(
      type: MetricType.sleep,
      label: 'Giấc ngủ',
      icon: AppIcons.sleep,
    ),
    MetricOption(
      type: MetricType.stepsCount,
      label: 'Số bước chân',
      icon: AppIcons.steps,
    ),
    MetricOption(
      type: MetricType.caloriesBurnt,
      label: 'Lượng calo',
      icon: Icons.local_fire_department_outlined,
    ),
  ];

  /// Returns all available metric options with labels and icons
  /// @deprecated Use [availableMetrics] constant instead
  static List<MetricOption> getAvailableMetrics() {
    return availableMetrics;
  }

  /// Returns metric option for a specific metric type
  static MetricOption getMetricOption(MetricType type) {
    return availableMetrics.firstWhere(
      (m) => m.type == type,
      orElse: () => throw ArgumentError('Metric type not found: $type'),
    );
  }
}




