import 'package:flutter/material.dart';
import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';

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
  
  // Helper methods
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withValues(alpha: opacity));
  }
}


