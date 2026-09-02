import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Màn hình báo lỗi dùng chung: icon tròn + thông điệp + nút "Thử lại".
///
/// Dùng cho lỗi chiếm cả vùng nội dung (tải danh sách thất bại). Với lỗi nhỏ
/// trong dialog/form hãy dùng `InlineMessageMixin`, với lỗi thoáng qua dùng
/// `ToastUtils`.
///
/// Chuỗi [message] nên lấy từ `UserFacingError.message(error)` để không lộ
/// thuật ngữ kỹ thuật cho người dùng.
///
/// ```dart
/// ErrorDisplayWidget(
///   title: 'Không tải được danh sách',
///   message: UserFacingError.message(state.error),
///   onRetry: () => bloc.add(const FetchMedications()),
///   wrapInCard: true,
/// )
/// ```
class ErrorDisplayWidget extends StatelessWidget {
  /// Khi có [title]: hiển thị tiêu đề + [message] làm mô tả chi tiết.
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData? icon;

  /// Bọc nội dung trong card (vd. màn Thuốc).
  final bool wrapInCard;

  const ErrorDisplayWidget({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.icon,
    this.wrapInCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      padding: EdgeInsets.all(wrapInCard ? 14 : AppSize.p24),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? Icons.error_outline,
        size: wrapInCard ? 32 : 48,
        color: AppColors.error,
      ),
    );

    final titleStyle = wrapInCard
        ? AppTextStyles.h4
        : const TextStyle(
            fontSize: AppSize.fontSize18,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          );

    final body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        SizedBox(height: wrapInCard ? 20 : AppSize.spacing24),
        if (title != null) ...[
          Text(
            title!,
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            message ?? 'Đã có lỗi xảy ra',
            style: wrapInCard
                ? AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey)
                : TextStyle(
                    fontSize: AppSize.fontSize14,
                    color: AppColors.textGrey,
                  ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          Text(
            message ?? 'Đã có lỗi xảy ra',
            style: const TextStyle(
              fontSize: AppSize.fontSize18,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSize.spacing8),
          Text(
            'Vui lòng thử lại sau',
            style: TextStyle(
              fontSize: AppSize.fontSize14,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (onRetry != null) ...[
          SizedBox(height: wrapInCard ? 24 : AppSize.spacing32),
          SizedBox(
            width: wrapInCard ? double.infinity : null,
            child: wrapInCard
                ? FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Thử lại'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSize.p24,
                        vertical: AppSize.p12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSize.r12),
                      ),
                      elevation: 0,
                    ),
                  ),
          ),
        ],
      ],
    );

    final padded = Padding(
      padding: EdgeInsets.all(wrapInCard ? 28 : AppSize.p24),
      child: body,
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(wrapInCard ? 24 : 0),
        child: wrapInCard
            ? ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.cardShadowList,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: padded,
                ),
              )
            : padded,
      ),
    );
  }
}
