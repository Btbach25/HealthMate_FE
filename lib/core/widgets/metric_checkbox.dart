import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/models/ui/metric_option.dart';
import 'package:flutter/material.dart';

/// Reusable checkbox widget for metric selection
/// Used in dialogs and forms for selecting health metrics
class MetricCheckbox extends StatelessWidget {
  final MetricOption metric;
  final bool isSelected;
  final ValueChanged<bool> onChanged;
  final double? width;
  final bool showCheckbox;
  final bool showCheckIcon;

  const MetricCheckbox({
    super.key,
    required this.metric,
    required this.isSelected,
    required this.onChanged,
    this.width,
    this.showCheckbox = true,
    this.showCheckIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: const EdgeInsets.all(AppSize.p16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSize.r12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (showCheckbox) ...[
              Checkbox(
                value: isSelected,
                onChanged: (value) => onChanged(value ?? false),
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
                color: isSelected
                    ? Colors.white
                    : AppColors.textGrey,
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
    );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }

    return content;
  }
}




