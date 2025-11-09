import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

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