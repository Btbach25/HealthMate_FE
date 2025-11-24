import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/presentation/home/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class StatsGrid extends StatelessWidget {
  final User user;
  const StatsGrid({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final heartRate = user.heartRate?.value?.round().toString() ?? '...';
    final weight = user.weight?.value?.round().toString() ?? '...';
    final systolic = user.bloodPressure?.systolic?.toString() ?? '...';
    final diastolic = user.bloodPressure?.diastolic?.toString() ?? '...';
    final bloodPressure = '$systolic/$diastolic';
    final temperatureValue = user.temperature?.value;
    final temperature = temperatureValue != null
        ? '${temperatureValue.toStringAsFixed(1)}'
        : 'Chưa có dữ liệu';
    final temperatureUnit = temperatureValue != null ? '°C' : null;

    const horizontalSpacing = SizedBox(width: 16);
    const verticalSpacing = SizedBox(height: 16);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: AppIcons.heart,
                iconColor: AppColors.heartIconColor,
                iconBgColor: AppColors.heartIconBg,
                title: 'Nhịp tim',
                value: heartRate,
                unit: 'bpm',
              ),
            ),
            horizontalSpacing,
            Expanded(
              child: StatCard(
                icon: AppIcons.weight,
                iconColor: AppColors.weightIconColor,
                iconBgColor: AppColors.weightIconBg,
                title: 'Cân nặng',
                value: weight,
                unit: 'kg',
              ),
            ),
          ],
        ),
        verticalSpacing,
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: AppIcons.bloodPressure,
                iconColor: AppColors.bloodPressureIconColor,
                title: 'Huyết áp',
                value: bloodPressure,
                unit: 'mmHg',
              ),
            ),
            horizontalSpacing,
            Expanded(
              child: StatCard(
                icon: AppIcons.temperature,
                iconColor: AppColors.tempIconColor,
                iconBgColor: AppColors.tempIconBg,
                title: 'Nhiệt độ',
                value: temperature,
                unit: temperatureUnit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}