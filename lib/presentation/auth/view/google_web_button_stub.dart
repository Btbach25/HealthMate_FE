import 'package:flutter/material.dart';

/// Bản stub của nút "Đăng nhập với Google" cho các nền tảng KHÔNG phải web.
///
/// Tồn tại chỉ để conditional import (`google_web_button_stub.dart` /
/// `google_web_button_impl.dart`) biên dịch được trên native — bản impl phụ
/// thuộc `dart:ui_web`/`package:web` nên không thể build cho Android/iOS.
/// Trên native, `LoginPage` kiểm tra `kIsWeb` và không bao giờ render widget
/// này, vì vậy nó trả về `SizedBox.shrink()`.
///
/// Nếu thêm tham số cho `GoogleWebButton` bên impl, phải thêm y hệt ở đây,
/// nếu không build native sẽ hỏng.
class GoogleWebButton extends StatelessWidget {
  const GoogleWebButton({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
