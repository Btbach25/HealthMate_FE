import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Cho phép kéo mọi vùng cuộn bằng **chuột** trên web và desktop.
///
/// Mặc định `MaterialScrollBehavior.dragDevices` chỉ nhận ngón tay, bút và
/// trackpad — con chuột bị loại. Hậu quả trên web: `PageView`, `ListView`,
/// `SingleChildScrollView`… đều "chết cứng" khi người dùng bấm giữ rồi kéo,
/// dù cuộn bằng bánh xe vẫn chạy. Đó là lý do carousel chỉ số ở trang chủ
/// không lướt được bằng chuột.
///
/// Khai báo một lần ở `MaterialApp.router(scrollBehavior: ...)` để áp dụng cho
/// toàn app; đừng vá lẻ từng widget cuộn.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
