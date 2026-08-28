import 'package:fe/core/config/app_config.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:flutter/material.dart';

/// Dải băng nhắc người xem rằng app đang chạy bằng **dữ liệu giả lập**.
///
/// - Chỉ hiển thị khi `AppConfig.isDemoMode == true`; ngoài chế độ demo widget
///   trả về [SizedBox.shrink] nên có thể chèn thoải mái vào UI thật.
/// - Hiển thị sẵn tài khoản demo để người xem đăng nhập ngay được.
///
/// Widget cố tình **không** phụ thuộc theme/hằng số riêng của app (chỉ dùng
/// Material mặc định) để có thể chèn vào bất kỳ màn hình nào mà không kéo theo
/// dependency.
///
/// Ví dụ:
/// ```dart
/// const DemoModeBanner(),                       // đầy đủ, kèm tài khoản demo
/// const DemoModeBanner(showCredentials: false), // gọn, chỉ nhắc chế độ demo
/// ```
class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({
    super.key,
    this.showCredentials = true,
    this.margin = const EdgeInsets.fromLTRB(24, 0, 24, 16),
  });

  /// Hiện thêm dòng email/mật khẩu của tài khoản demo.
  final bool showCredentials;

  /// Lề ngoài của dải băng.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isDemoMode) return const SizedBox.shrink();

    const amber = Color(0xFFB45309);

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5C97B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_outlined, size: 20, color: amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chế độ DEMO — dữ liệu giả lập',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: amber,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ứng dụng không gọi máy chủ; mọi chỉ số đều là dữ liệu mẫu.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7C5A17)),
                ),
                if (showCredentials) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Tài khoản: ${MockUsers.demoEmail}\n'
                    'Mật khẩu: ${MockUsers.demoPassword}  •  OTP: ${MockUsers.demoOtp}',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C5A17),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
