import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Reusable text field widget for profile settings
/// Standardized styling and behavior
class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? suffixText;
  final String? hintText;
  final String? Function(String?)? validator;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.enabled = true,
    this.keyboardType,
    this.suffixText,
    this.hintText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null 
            ? Icon(icon, color: AppColors.primary.withValues(alpha: 0.7))
            : null,
        suffixText: suffixText,
        filled: true,
        fillColor: enabled ? AppColors.inputBackground : AppColors.surfaceVariant,
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
          borderSide: BorderSide(color: AppColors.inputBorder),
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

