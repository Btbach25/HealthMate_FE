import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:flutter/material.dart';

class StatsHeaderCard extends StatelessWidget {
  final int totalReadings;
  final int totalTypes;

  const StatsHeaderCard({
    super.key,
    required this.totalReadings,
    required this.totalTypes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.statsHeaderIconBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.statsHeader,
              color: AppColors.statsHeaderIconColor,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chỉ số sức khỏe',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Theo dõi sức khỏe hàng ngày',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTag('$totalReadings chỉ số'),
                    const SizedBox(width: 8),
                    _buildTag('$totalTypes loại'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textGrey,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}