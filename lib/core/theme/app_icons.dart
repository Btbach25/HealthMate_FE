import 'package:flutter/material.dart';

/// Đường dẫn tới file ảnh trong `assets/icons/`.
///
/// Dùng hằng ở đây thay vì gõ chuỗi đường dẫn trong widget: gõ sai chuỗi chỉ
/// vỡ lúc chạy, còn sai tên hằng thì trình biên dịch bắt ngay.
///
/// Thêm ảnh mới nhớ khai báo thư mục trong `pubspec.yaml` phần `assets`.
class AppAssets {
  static const String happy = 'assets/icons/happy.png';
  static const String neutral = 'assets/icons/neutral.png';
  static const String sad = 'assets/icons/sad-face.png';
  static const String appLogo = 'assets/icons/app_logo.png';
  static const String googleLogo = 'assets/icons/google_logo.png';
}

/// Bí danh cho các icon Material dùng lặp lại trong app.
///
/// Có để một icon chỉ khai báo một lần: đổi icon nhịp tim thì sửa ở đây, mọi
/// màn hình đổi theo. Gọi thẳng `Icons.*` chỉ nên dùng cho icon xuất hiện
/// đúng một chỗ.
class AppIcons {
  // Chỉ số sức khoẻ
  static const IconData heart = Icons.favorite_border;
  static const IconData weight = Icons.monitor_weight_outlined;
  static const IconData bloodPressure = Icons.show_chart;
  static const IconData spo2 = Icons.bloodtype_outlined;
  static const IconData temperature = Icons.thermostat_outlined;

  // Bottom navigation
  static const IconData home = Icons.home_filled;
  static const IconData family = Icons.people_outline;
  static const IconData stats = Icons.bar_chart_outlined;
  static const IconData medication = Icons.medical_services_outlined;
  static const IconData settings = Icons.settings_outlined;

  // Mức độ ưu tiên của thẻ / thông báo
  static const IconData info = Icons.info_outline;
  static const IconData important = Icons.star_border;
  static const IconData urgent = Icons.warning_amber_rounded;
  
  static const IconData userAvatar = Icons.person_outline;

  // Màn Chỉ số / Xem chi tiết
  static const IconData statsHeader = Icons.insert_chart_outlined;
  static const IconData viewDetails = Icons.visibility_outlined;
  static const IconData add = Icons.add;
  static const IconData trendUp = Icons.trending_up;
  static const IconData trendDown = Icons.trending_down;
  static const IconData steps = Icons.directions_walk;
  static const IconData sleep = Icons.bedtime_outlined;
}