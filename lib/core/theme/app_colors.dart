import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF24A66D);
  static const Color primaryDark = Color(0xFF1E8A5A);
  static const Color primaryLight = Color(0xFF4FB883);
  static const Color primaryContainer = Color(0xFFE9F6F0);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Input Colors
  static const Color inputBackground = Color(0xFFF7F8F9);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFocusBorder = primary;
  
  // Text Colors
  static const Color textBlack = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF424242);
  static const Color textGrey = Color(0xFF8A8A8E);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // Status Colors
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  
  // Card Colors
  static const Color cardBorder = Color(0xFFEDEDED);
  static const Color cardShadow = Color(0x1A000000);
  
  // Tag Colors
  static const Color tagUrgentText = error;
  static const Color tagUrgentBg = errorLight;
  static const Color tagImportantText = primary;
  static const Color tagImportantBg = primaryContainer;
  static const Color tagInfoText = textGrey;
  static const Color tagInfoBg = inputBackground;
  static const Color tagWarningText = warning;
  static const Color tagWarningBg = warningLight;
  static const Color tagNormalText = primary;
  static const Color tagNormalBg = primaryContainer;
  
  // Icon Colors
  static const Color heartIconColor = tagUrgentText;
  static const Color heartIconBg = tagUrgentBg;
  static const Color weightIconColor = primary;
  static const Color weightIconBg = tagImportantBg;
  static const Color bloodPressureIconColor = primary;
  static const Color tempIconColor = warning;
  static const Color tempIconBg = tagWarningBg;
  static const Color statsHeaderIconBg = primary;
  static const Color statsHeaderIconColor = Colors.white;
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient primaryLightGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow Colors
  static List<BoxShadow> get cardShadowList => [
    BoxShadow(
      color: cardShadow,
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get cardShadowHover => [
    BoxShadow(
      color: cardShadow.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

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