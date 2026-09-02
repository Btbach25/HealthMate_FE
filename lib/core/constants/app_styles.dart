import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Bộ kiểu chữ CŨ, còn dùng ở màn Đăng nhập/Đăng ký và vài widget khác.
///
/// Bộ đang dùng cho code mới là `AppTextStyles`
/// (`lib/core/theme/app_text_styles.dart`) — đầy đủ hơn và có `height`,
/// `letterSpacing`.
///
/// Hai bộ KHÔNG tương đương từng cặp (vd. `AppStyles.h1` và
/// `AppTextStyles.h1` cùng cỡ 32 nhưng khác `height`/`letterSpacing`), nên
/// thay thế hàng loạt sẽ làm xê dịch bố cục các màn đang chạy. Giữ nguyên chỗ
/// cũ, chỉ dùng `AppTextStyles` cho phần viết mới.
class AppStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textBlack,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    color: AppColors.textGrey,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textBlack,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );
}
