import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable date field widget for profile settings
/// Standardized styling and behavior
class ProfileDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? hintText;

  const ProfileDateField({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
    this.onClear,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
          suffixIcon: value != null && enabled && onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: enabled ? AppColors.inputBackground : AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSize.p16,
            vertical: AppSize.p16,
          ),
        ),
        child: Text(
          value != null
              ? DateFormat('dd/MM/yyyy').format(value!)
              : (hintText ?? 'Chọn ngày'),
          style: AppTextStyles.bodyMedium.copyWith(
            color: value != null
                ? AppColors.textBlack
                : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

