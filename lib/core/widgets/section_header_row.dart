import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Hàng tiêu đề có icon (form, section trong app).
class SectionHeaderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool showRequiredMark;

  const SectionHeaderRow({
    super.key,
    required this.icon,
    required this.title,
    this.showRequiredMark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.labelLarge),
        if (showRequiredMark) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
