import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Logo + tên ứng dụng đặt ở đầu các màn xác thực.
///
/// Không có tham số. Tự fallback sang icon vector nếu
/// `assets/icons/app_logo.png` thiếu (ví dụ khi asset chưa được khai báo trong
/// `pubspec.yaml` của một target build), nên an toàn khi dùng ở mọi nền tảng.
///
/// Khi nào nên tái sử dụng: các màn ngoài shell chưa đăng nhập cần nhận diện
/// thương hiệu. Thường không cần dùng trực tiếp: `AuthFormLayout` đã bao sẵn.
class AuthLogoHeader extends StatelessWidget {
  const AuthLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 36, bottom: 20),
      child: Column(
        children: [
          Image.asset(
            'assets/icons/app_logo.png',
            height: 52,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.health_and_safety_outlined,
              size: 52,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'HealthMate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
