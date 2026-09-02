import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Thang kiểu chữ chính của app — dùng bộ này cho code mới.
///
/// Cách chọn: `h1`–`h4` cho tiêu đề, `bodyLarge/Medium/Small` cho văn bản,
/// `labelLarge/Medium/Small` cho nhãn và tiêu đề nhỏ in đậm, `caption` cho
/// chú thích mờ, `buttonLarge/Medium` cho chữ trên nút.
///
/// Cần đổi màu thì `copyWith` chứ đừng dựng `TextStyle` mới:
/// `AppTextStyles.bodyMedium.copyWith(color: AppColors.error)`.
///
/// **Lưu ý:** trong repo còn `AppStyles` (`lib/core/constants/app_styles.dart`)
/// là bộ kiểu chữ cũ, tên gần giống nhưng giá trị KHÔNG bằng nhau (bộ này có
/// `height` và `letterSpacing`). Hai bộ vẫn song song vì đang được dùng ở
/// nhiều màn khác nhau — đổi qua lại sẽ làm xê dịch bố cục. Code mới dùng
/// `AppTextStyles`.
class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: AppSize.fontSize32,
    fontWeight: FontWeight.bold,
    color: AppColors.textBlack,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: AppSize.fontSize28,
    fontWeight: FontWeight.bold,
    color: AppColors.textBlack,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: AppSize.fontSize24,
    fontWeight: FontWeight.w600,
    color: AppColors.textBlack,
    height: 1.4,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: AppSize.fontSize20,
    fontWeight: FontWeight.w600,
    color: AppColors.textBlack,
    height: 1.4,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppSize.fontSize18,
    fontWeight: FontWeight.normal,
    color: AppColors.textBlack,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppSize.fontSize16,
    fontWeight: FontWeight.normal,
    color: AppColors.textBlack,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: AppSize.fontSize14,
    fontWeight: FontWeight.normal,
    color: AppColors.textBlack,
    height: 1.5,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: AppSize.fontSize16,
    fontWeight: FontWeight.w600,
    color: AppColors.textBlack,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: AppSize.fontSize14,
    fontWeight: FontWeight.w600,
    color: AppColors.textBlack,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: AppSize.fontSize12,
    fontWeight: FontWeight.w500,
    color: AppColors.textGrey,
    height: 1.4,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: AppSize.fontSize12,
    fontWeight: FontWeight.normal,
    color: AppColors.textGrey,
    height: 1.4,
  );

  // Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontSize: AppSize.fontSize16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: AppSize.fontSize14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
    letterSpacing: 0.3,
  );

  /// Đổi màu một style. Hiện chưa nơi nào dùng — trong app đang gọi thẳng
  /// `style.copyWith(color: ...)`, ngắn hơn và quen tay hơn.
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Giảm độ đậm của màu chữ sẵn có xuống [opacity] (0–1).
  ///
  /// Hiện chưa nơi nào dùng. Style không đặt màu (`style.color == null`) thì
  /// trả về nguyên trạng, chữ vẫn lấy màu mặc định của theme.
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withValues(alpha: opacity));
  }
}
