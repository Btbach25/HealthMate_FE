import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class MedicationDialogHeader extends StatelessWidget {
  const MedicationDialogHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 6, 10),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: closeEnabled ? onClose : null,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textGrey,
            tooltip: 'Đóng',
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
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
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
