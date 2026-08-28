import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Hàng bật/tắt trong Cài đặt: icon + tiêu đề + mô tả + `Switch`.
///
/// Thiết kế để đặt trong `children` của `SettingsCard` (icon dùng cùng kiểu
/// nền bo góc nên hai widget khớp nhau về thị giác).
///
/// Cả hàng được bọc `Semantics` với `excludeSemantics: true`: trình đọc màn
/// hình đọc "tiêu đề. mô tả" một lần cùng trạng thái bật/tắt, thay vì đọc rời
/// từng `Text`. Vì vậy đừng thêm `Semantics` bọc ngoài nữa.
///
/// Chỉ bấm được đúng vào `Switch` — nếu cần bấm cả hàng thì bọc thêm
/// `InkWell` ở phía gọi.
///
/// ```dart
/// SettingsSwitchRow(
///   icon: Icons.notifications_active_outlined,
///   title: 'Nhắc uống thuốc',
///   description: 'Gửi thông báo theo lịch đã đặt.',
///   value: settings.reminderEnabled,
///   onChanged: _toggleReminder,
/// )
/// ```
class SettingsSwitchRow extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const SettingsSwitchRow({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = enabled ? AppColors.primary : AppColors.textGrey;
    final effectiveIconBg = enabled ? AppColors.primaryContainer : AppColors.surfaceVariant;

    return Semantics(
      label: '$title. $description',
      toggled: value,
      enabled: enabled,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: effectiveIconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: enabled ? AppColors.textBlack : AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            splashRadius: 0,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return Colors.grey[300];
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.primary;
              return Colors.grey[300];
            }),
          ),
        ],
      ),
    );
  }
}
