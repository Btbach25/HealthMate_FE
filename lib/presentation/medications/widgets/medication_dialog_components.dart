import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class MedicationDialogHeader extends StatelessWidget {
  const MedicationDialogHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 12, 14),
    this.closeEnabled = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;
  final EdgeInsetsGeometry padding;
  final bool closeEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.medication_liquid_rounded,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: closeEnabled ? onClose : null,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textGrey,
              tooltip: 'Đóng',
            ),
          ),
        ],
      ),
    );
  }
}

class MedicationSectionCard extends StatelessWidget {
  const MedicationSectionCard({
    super.key,
    required this.child,
    this.title,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 14),
  });

  final String? title;
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}
