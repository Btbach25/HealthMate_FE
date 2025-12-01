import 'package:flutter/material.dart';
import 'health_overview.dart';

class StatCardConfig {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final String unit;
  final String Function(HealthOverview overview) getValue;

  StatCardConfig({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.iconBgColor,
    required this.unit,
    required this.getValue,
  });
}