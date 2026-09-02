import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Card gom một nhóm mục cài đặt: hàng tiêu đề (icon + [title] + [trailing])
/// và danh sách [children] bên dưới.
///
/// Là khối dựng cơ bản của các tab Cài đặt — mỗi nhóm chức năng một card.
/// Card tự chừa `margin` dưới 16px nên xếp liên tiếp trong `Column` /
/// `ListView` là đủ, không cần thêm `SizedBox` ngăn cách.
///
/// Đường kẻ ngăn tiêu đề với nội dung chỉ xuất hiện khi [children] không rỗng,
/// nên card chỉ-có-tiêu-đề (kèm [trailing] là một `Switch`) vẫn gọn.
///
/// ```dart
/// SettingsCard(
///   icon: Icons.notifications_outlined,
///   title: 'Thông báo',
///   children: [
///     SettingsSwitchRow(...),
///   ],
/// )
/// ```
class SettingsCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const SettingsCard({
    super.key,
    this.icon,
    required this.title,
    required this.children,
    this.trailing,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          if (children.isNotEmpty) ...[
            const Divider(
              height: 28,
              thickness: 0.8,
              color: AppColors.cardBorder,
            ),
            ...children,
          ],
        ],
      ),
    );
  }
}
