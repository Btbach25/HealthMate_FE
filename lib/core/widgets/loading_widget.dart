import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Chỉ báo đang tải, căn giữa, kèm thông điệp tuỳ chọn.
///
/// Dùng cho trạng thái chờ chiếm cả vùng nội dung. Bật [isFullScreen] khi
/// widget đứng một mình thay cho cả trang (nó tự dựng `Scaffold`) — đừng bật
/// khi đã nằm trong `Scaffold` của màn hình, sẽ lồng hai `Scaffold`.
///
/// Nút bấm đang chờ thì dùng `LoadingButton` thay vì widget này.
///
/// ```dart
/// LoadingWidget(
///   message: 'Đang tải danh sách thuốc',
///   subtitle: 'Vui lòng đợi…',
///   progressInElevatedCircle: true,
/// )
/// ```
class LoadingWidget extends StatelessWidget {
  final String? message;

  /// Dòng phụ dưới [message] (vd. "Vui lòng đợi…").
  final String? subtitle;
  final bool isFullScreen;

  /// Bọc indicator trong vòng tròn có shadow (màn chi tiết / Thuốc).
  final bool progressInElevatedCircle;

  const LoadingWidget({
    super.key,
    this.message,
    this.subtitle,
    this.isFullScreen = false,
    this.progressInElevatedCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = progressInElevatedCircle
        ? Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: AppColors.cardShadowList,
            ),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          )
        : const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          );

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        if (message != null) ...[
          SizedBox(height: progressInElevatedCircle ? 24 : 16),
          Text(
            message!,
            style: progressInElevatedCircle
                ? AppTextStyles.labelLarge
                : const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
}
