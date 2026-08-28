import 'package:fe/core/constants/app_size.dart';
import 'package:fe/presentation/auth/widgets/auth_logo_header.dart';
import 'package:flutter/material.dart';

/// Khung bố cục dùng chung cho các màn xác thực: logo HealthMate ở trên, form
/// nằm trong một card bo góc có đổ bóng, toàn bộ cuộn được để bàn phím không
/// che mất input.
///
/// Tham số bắt buộc:
/// - [child]: nội dung form, thường là `Column` với
///   `crossAxisAlignment: CrossAxisAlignment.stretch`.
///
/// Tham số tuỳ chọn:
/// - [cardColor]: màu nền card, mặc định [Colors.white]. Màn OTP truyền
///   `AppColors.background` để card ngả xám nhẹ.
///
/// Khi nào nên tái sử dụng: bất kỳ màn nào trong `presentation/auth/` cần bố
/// cục "logo + card form". Dùng widget này thay vì copy lại
/// `Container`/`BoxShadow`, để các màn auth luôn đồng nhất padding, bo góc và
/// độ đổ bóng — sửa một chỗ là cả luồng auth đổi theo.
class AuthFormLayout extends StatelessWidget {
  final Widget child;
  final Color cardColor;

  const AuthFormLayout({
    super.key,
    required this.child,
    this.cardColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthLogoHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSize.p24,
                0,
                AppSize.p24,
                AppSize.p32,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSize.p24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppSize.r12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 5,
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
