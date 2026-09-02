import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/widgets/clickable.dart';
import 'package:fe/data/models/ui/metric_option.dart';
import 'package:flutter/material.dart';

/// Ô chọn một chỉ số sức khoẻ (icon + tên + trạng thái chọn).
///
/// Dùng trong dialog/form chọn chỉ số chia sẻ với nhóm. Cả ô đều bấm được,
/// không riêng ô vuông checkbox.
///
/// Hai kiểu hiển thị trạng thái chọn — chọn MỘT cho nhất quán trong cùng danh
/// sách: [showCheckbox] (ô vuông bên trái, hợp danh sách dọc) hoặc
/// [showCheckIcon] (dấu tick bên phải, hợp lưới/chip).
///
/// Đặt [enabled] = false cho chỉ số backend chưa hỗ trợ — kiểm tra bằng
/// `MetricSelectionHelper.isMetricSupportedByBackend`.
///
/// ```dart
/// MetricCheckbox(
///   metric: option,
///   isSelected: selected.contains(option.type),
///   enabled: MetricSelectionHelper.isMetricSupportedByBackend(option.type),
///   onChanged: (v) => _toggle(option.type, v),
/// )
/// ```
class MetricCheckbox extends StatelessWidget {
  final MetricOption metric;
  final bool isSelected;
  final ValueChanged<bool> onChanged;
  final double? width;
  final bool showCheckbox;
  final bool showCheckIcon;
  final bool enabled;

  const MetricCheckbox({
    super.key,
    required this.metric,
    required this.isSelected,
    required this.onChanged,
    this.width,
    this.showCheckbox = true,
    this.showCheckIcon = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Clickable(
        onTap: enabled ? () => onChanged(!isSelected) : null,
        child: Container(
          padding: const EdgeInsets.all(AppSize.p16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : Colors.white,
            borderRadius: BorderRadius.circular(AppSize.r12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (showCheckbox) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: enabled
                      ? (value) => onChanged(value ?? false)
                      : null,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  metric.icon,
                  color: isSelected ? Colors.white : AppColors.textGrey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  metric.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showCheckIcon && isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }

    return content;
  }
}
