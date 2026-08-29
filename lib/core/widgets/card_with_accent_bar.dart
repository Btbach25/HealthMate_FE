import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Card trắng có thanh gradient mảnh chạy ngang trên cùng (accent bar).
///
/// Dùng để làm nổi một khối nội dung quan trọng so với card thường. [child]
/// tự lo padding của mình — widget này chỉ vẽ khung, viền và thanh accent.
///
/// ```dart
/// CardWithAccentBar(
///   child: Padding(
///     padding: const EdgeInsets.all(16),
///     child: Text('Nội dung'),
///   ),
/// )
/// ```
class CardWithAccentBar extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double barHeight;

  const CardWithAccentBar({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.barHeight = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadowList,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: barHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
