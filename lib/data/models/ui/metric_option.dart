import 'package:equatable/equatable.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:flutter/material.dart';

/// Model for metric option used in UI (dialogs, forms, etc.)
/// Contains metric type, display label, and icon
class MetricOption extends Equatable {
  final MetricType type;
  final String label;
  final IconData icon;

  const MetricOption({
    required this.type,
    required this.label,
    required this.icon,
  });

  @override
  List<Object> get props => [type, label, icon];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetricOption &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;
}





