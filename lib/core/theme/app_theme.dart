import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Theme dùng chung cho toàn app.
///
/// Mọi màu sắc lấy từ [AppColors], mọi khoảng cách/bo góc lấy từ [AppSize] —
/// không hard-code giá trị mới ở đây để giữ một nguồn sự thật duy nhất.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
    primaryColor: AppColors.primary,
    // NOTE: pubspec.yaml đang bundle font 'Lato'. Giữ 'Inter' để không đổi
    // giao diện hiện tại; muốn dùng Lato thì đổi cả hai chỗ cùng lúc.
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(primary: AppColors.primary),
    inputDecorationTheme: _inputDecorationTheme,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
  );

  static const _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.inputBackground,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSize.p16,
      vertical: 14,
    ),
    border: _border,
    enabledBorder: _border,
    focusedBorder: OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: AppColors.error, width: 1.5),
    ),
    hintStyle: TextStyle(color: AppColors.textLight, fontSize: 15),
    prefixIconColor: AppColors.textGrey,
  );

  static const _radius = BorderRadius.all(Radius.circular(AppSize.r12));

  static const _border = OutlineInputBorder(
    borderRadius: _radius,
    borderSide: BorderSide(color: AppColors.inputBorder),
  );
}
