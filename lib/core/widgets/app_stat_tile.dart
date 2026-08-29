import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Ô thống kê dạng thẻ: icon có nền màu + con số + nhãn.
///
/// Dùng cho hàng KPI ở đầu màn hình (hiện dùng ở tab Thuốc, tái dùng được cho
/// dashboard). Widget tự co theo cha nên hãy đặt trong `Expanded` / `Row`
/// hoặc `GridView` để chia đều chiều ngang.
///
/// ```dart
/// Expanded(
///   child: AppStatTile(
///     icon: Icons.medication_outlined,
///     iconBg: AppColors.primaryContainer,
///     iconColor: AppColors.primary,
///     value: 12,
///     label: 'Đang dùng',
///     valueColor: AppColors.primary,
///   ),
/// )
/// ```
class AppStatTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final int value;
  final String label;
  final Color valueColor;

  const AppStatTile({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(
              color: valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
