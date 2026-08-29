import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Ô nhập văn bản chuẩn của app (nền xám nhạt, bo 12, viền primary khi focus).
///
/// Là `TextFormField` nên dùng được trực tiếp với [validator] bên trong `Form`.
/// Hãy dùng widget này thay vì tự dựng `TextFormField` + `InputDecoration`,
/// để mọi form trong app giữ chung một kiểu.
///
/// Phân biệt hai cờ:
/// - [enabled] = false: ô bị vô hiệu hoá (chế độ xem hồ sơ), chữ đậm hơn và
///   xám đi.
/// - [readOnly] = true: ô vẫn "sáng" và nhận [onTap] nhưng không gõ được —
///   dùng cho ô mở picker (chọn ngày, chọn giờ).
///
/// ```dart
/// ProfileTextField(
///   controller: _nameCtrl,
///   label: 'Họ tên',
///   icon: Icons.person_outline,
///   validator: (v) => FormValidationHelper.validateRequired(v, fieldName: 'họ tên'),
/// )
/// ```
class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final String? suffixText;
  final String? hintText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.suffixText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = enabled ? AppColors.textBlack : AppColors.textSecondary;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium.copyWith(
        color: textColor,
        fontWeight: enabled ? FontWeight.w400 : FontWeight.w500,
      ),
      onChanged: onChanged,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: enabled ? AppColors.textGrey : AppColors.textSecondary,
          fontWeight: enabled ? FontWeight.w400 : FontWeight.w500,
        ),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: enabled ? AppColors.textGrey : AppColors.textSecondary,
          fontWeight: enabled ? FontWeight.w500 : FontWeight.w600,
        ),
        prefixIcon: icon != null 
            ? Icon(icon, color: AppColors.primary.withValues(alpha: 0.7))
            : null,
        suffixText: suffixText,
        filled: true,
        fillColor: enabled ? AppColors.inputBackground : AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r12),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r12),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r12),
          borderSide: BorderSide(
            color: AppColors.inputBorder.withValues(alpha: 0.85),
            width: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSize.p16,
          vertical: AppSize.p16,
        ),
      ),
      validator: validator,
    );
  }
}

