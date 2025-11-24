import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF24A66D);
  static const Color background = Colors.white;
  static const Color inputBackground = Color(0xFFF7F8F9);
  static const Color textBlack = Color(0xFF1E1E1E);
  static const Color textGrey = Color(0xFF8A8A8E);
  static const Color error = Colors.red;
  static const Color success = Colors.green;

  static const Color cardBorder = Color(0xFFEDEDED);

  static const Color tagUrgentText = Color(0xFFE53935);
  static const Color tagUrgentBg = Color(0xFFFFEBEE);

  static const Color tagImportantText = primary;
  static const Color tagImportantBg = Color(0xFFE9F6F0);

  static const Color tagInfoText = textGrey;
  static const Color tagInfoBg = inputBackground;


  static const Color heartIconColor = tagUrgentText;
  static const Color heartIconBg = tagUrgentBg;

  static const Color weightIconColor = primary;
  static const Color weightIconBg = tagImportantBg;

  static const Color bloodPressureIconColor = primary;

  static const Color tempIconColor = Color(0xFFF57C00);
  static const Color tempIconBg = Color(0xFFFFF8E1);

  // Xem chi tiết 
  static const Color tagWarningText = Color(0xFFF57C00);
  static const Color tagWarningBg = Color(0xFFFFF8E1);
  static const Color tagNormalText = primary;
  static const Color tagNormalBg = tagImportantBg;
  static const Color statsHeaderIconBg = primary;
  static const Color statsHeaderIconColor = Colors.white;

  static Color getIconColorForType(String type) {
    switch (type) {
      case 'heartRate':
        return heartIconColor;
      case 'weight':
        return weightIconColor;
      // Thêm các loại khác nếu cần
      default:
        return Colors.grey; // Màu mặc định
    }
  }

  static Color getIconBgColorForType(String type) {
    switch (type) {
      case 'heartRate':
        return heartIconBg;
      case 'weight':
        return weightIconBg;
      // Thêm các loại khác nếu cần
      default:
        return Colors.grey[200]!;
    }
  }
}