import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class MedicationItemCard extends StatelessWidget {
  final String name;
  final String dosage;
  final String time;
  final bool taken;
  final bool isOverdue;
  final VoidCallback onTap;

  const MedicationItemCard({
    super.key,
    required this.name,
    required this.dosage,
    required this.time,
    required this.taken,
    required this.isOverdue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = taken
        ? AppColors.primaryContainer
        : AppColors.surface;
    final Color borderColor = taken
        ? AppColors.primaryLight.withValues(alpha: 0.5)
        : AppColors.cardBorder;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          // Left: name + dosage
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dosage,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: time + status + checkbox
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: AppTextStyles.labelMedium),
              const SizedBox(height: 2),
              Text(
                taken
                    ? 'Đã uống'
                    : isOverdue
                        ? 'Bị lỡ'
                        : 'Chưa đến giờ',
                style: AppTextStyles.caption.copyWith(
                  color: taken
                      ? AppColors.primary
                      : isOverdue
                          ? AppColors.error
                          : AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Checkbox
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: taken ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: taken ? AppColors.primary : AppColors.cardBorder,
                  width: 2,
                ),
              ),
              child: taken
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
