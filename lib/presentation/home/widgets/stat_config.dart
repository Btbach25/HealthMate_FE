import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';

import '../../../data/models/health/stat_card_config.dart';
import '../../../data/models/health/health_overview.dart';

final List<StatCardConfig> defaultStatCardsConfig = [
  StatCardConfig(
    title: 'Nhịp tim',
    icon: AppIcons.heart,
    iconColor: AppColors.heartIconColor,
    iconBgColor: AppColors.heartIconBg,
    unit: 'bpm',
    getValue: (HealthOverview o) {
      final hr = o.heartRate?.value;
      return hr != null ? hr.round().toString() : '—';
    },
  ),
  StatCardConfig(
    title: 'Cân nặng',
    icon: AppIcons.weight,
    iconColor: AppColors.weightIconColor,
    iconBgColor: AppColors.weightIconBg,
    unit: 'kg',
    getValue: (HealthOverview o) {
      final w = o.weight?.value;
      return w != null ? w.round().toString() : '—';
    },
  ),
  StatCardConfig(
    title: 'Huyết áp',
    icon: AppIcons.bloodPressure,
    iconColor: AppColors.bloodPressureIconColor,
    iconBgColor: null,
    unit: 'mmHg',
    getValue: (HealthOverview o) {
      final systolic = o.bloodPressure?.systolic?.toString() ?? '—';
      final diastolic = o.bloodPressure?.diastolic?.toString() ?? '—';
      return '$systolic/$diastolic';
    },
  ),
  StatCardConfig(
    title: 'Nhiệt độ',
    icon: AppIcons.temperature,
    iconColor: AppColors.tempIconColor,
    iconBgColor: AppColors.tempIconBg,
    unit: '°C',
    getValue: (HealthOverview o) {
      final temp = o.temperature?.value;
      return temp != null ? temp.toStringAsFixed(1) : '—';
    },
  ),
];