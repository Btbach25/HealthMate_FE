import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:flutter/material.dart';

/// Extension for MetricType to provide display labels and icons
extension MetricTypeExtension on MetricType {
  /// Returns the Vietnamese display label for the metric type
  String get displayLabel {
    switch (this) {
      case MetricType.heartRate:
        return 'Nhịp tim';
      case MetricType.stepsCount:
        return 'Số bước chân';
      case MetricType.caloriesBurnt:
        return 'Lượng calo';
      case MetricType.bloodPressure:
        return 'Huyết áp';
      case MetricType.weight:
        return 'Cân nặng';
      case MetricType.sleep:
        return 'Giấc ngủ';
      case MetricType.temperature:
        return 'Nhiệt độ';
    }
  }

  /// Returns the icon for the metric type
  IconData get icon {
    switch (this) {
      case MetricType.heartRate:
        return AppIcons.heart;
      case MetricType.stepsCount:
        return AppIcons.steps;
      case MetricType.caloriesBurnt:
        return Icons.local_fire_department_outlined;
      case MetricType.bloodPressure:
        return AppIcons.bloodPressure;
      case MetricType.weight:
        return AppIcons.weight;
      case MetricType.sleep:
        return AppIcons.sleep;
      case MetricType.temperature:
        return AppIcons.temperature;
    }
  }
}

