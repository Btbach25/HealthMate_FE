import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Banner nền gradient đặt ở đầu trang: tiêu đề + mô tả + một [action].
///
/// Dùng làm khối "hero" mở đầu một tab (Gia đình, Thuốc…) khi cần kèm một
/// hành động chính. Banner tự đổi bố cục theo bề rộng khả dụng: dưới 520px
/// thì [action] xuống dòng, rộng hơn thì nằm cùng hàng bên phải — nên đặt nó
/// trong vùng có bề rộng xác định, đừng nhét vào `Row` không giới hạn.
///
/// ```dart
/// HeroActionBanner(
///   title: 'Nhóm gia đình',
///   subtitle: 'Theo dõi sức khoẻ người thân ở một nơi.',
///   action: LoadingButton(text: 'Tạo nhóm', onPressed: _create),
/// )
/// ```
class HeroActionBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget action;

  const HeroActionBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout = constraints.maxWidth < 520;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryContainer,
                AppColors.primaryContainer.withValues(alpha: 0.35),
                AppColors.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
            boxShadow: AppColors.cardShadowList,
          ),
          child: useVerticalLayout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BannerText(title: title, subtitle: subtitle),
                    const SizedBox(height: 12),
                    action,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _BannerText(title: title, subtitle: subtitle),
                    ),
                    const SizedBox(width: 12),
                    action,
                  ],
                ),
        );
      },
    );
  }
}

class _BannerText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BannerText({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(letterSpacing: -0.3),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary, height: 1.45),
        ),
      ],
    );
  }
}
