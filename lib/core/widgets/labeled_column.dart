import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Nhãn (kèm dấu * bắt buộc và gợi ý trong ngoặc) đặt trên một [child].
///
/// Dùng khi cần gắn nhãn cho ô nhập KHÔNG có `labelText` sẵn — dropdown tự
/// chế, ô chọn giờ, chip… Nếu [child] là `ProfileTextField` hay
/// `SettingsDropdown` thì đừng bọc thêm, hai widget đó đã có label riêng.
///
/// ```dart
/// LabeledColumn(
///   label: 'Giờ uống',
///   requiredField: true,
///   hintInParens: 'giờ địa phương',
///   child: _TimePickerRow(...),
/// )
/// ```
class LabeledColumn extends StatelessWidget {
  final String label;
  final String? hintInParens;
  final bool requiredField;
  final Widget child;

  const LabeledColumn({
    super.key,
    required this.label,
    this.hintInParens,
    this.requiredField = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (requiredField)
              Text(
                ' *',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            if (hintInParens != null) ...[
              const SizedBox(width: 6),
              Text(
                '($hintInParens)',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
