import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Card giới thiệu một tính năng: icon nền gradient + tiêu đề + mô tả,
/// tuỳ chọn thêm nút ở chân card.
///
/// Dùng cho các lối tắt/tính năng nổi bật trên trang chủ và tab Thuốc.
/// - [onTap]: làm cả card bấm được (thường để điều hướng). Có [onTap] thì card
///   được bọc `InkWell` nên có hiệu ứng ripple.
/// - [footer]: nút riêng ở chân card (vd. "Quét đơn thuốc"). Footer có
///   callback riêng của nó — đừng trông chờ [onTap] bắt được cú bấm ở đây.
/// - [showTrailingChevron]: chỉ bật khi card thực sự điều hướng sang màn khác.
///
/// ```dart
/// FeatureHighlightCard(
///   leadingIcon: Icons.document_scanner_outlined,
///   title: 'Quét đơn thuốc',
///   subtitle: 'Chụp ảnh đơn để tự tạo lịch uống.',
///   footer: LoadingButton(text: 'Quét ngay', onPressed: _scan),
/// )
/// ```
class FeatureHighlightCard extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showTrailingChevron;
  final Widget? footer;
  final double borderRadius;

  const FeatureHighlightCard({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showTrailingChevron = false,
    this.footer,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            footer != null ? 0 : 16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryLightGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  leadingIcon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.labelLarge,
                          ),
                        ),
                        if (showTrailingChevron) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textLight,
                            size: 28,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (footer != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: footer!,
            ),
          ),
        ],
      ],
    );

    final decoration = BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: AppColors.cardShadowList,
    );

    final shell = SizedBox(
      width: double.infinity,
      child: content,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            decoration: decoration,
            child: shell,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: shell,
    );
  }
}
