import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/models/user/medication_progress.dart';
import 'package:flutter/material.dart';

class MedicationCard extends StatelessWidget {
  final MedicationProgress progress;
  const MedicationCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final double percent = (progress.total > 0)
        ? progress.completed / progress.total
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thuốc hôm nay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã uống: ${progress.completed}/${progress.total}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.inputBackground,
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}