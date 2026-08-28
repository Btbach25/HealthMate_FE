import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ô "nhập lại mật khẩu" có nút ẩn/hiện, bắn `ConfirmPasswordChanged`.
///
/// Không nhận tham số: widget tự lấy bloc qua `context.read`, nên **bắt buộc**
/// phải đặt bên dưới một `BlocProvider<AuthFormBloc>`.
///
/// Widget này chỉ ghi giá trị vào state; việc so khớp với mật khẩu chính do
/// `AuthFormBloc` làm khi submit, nên ở đây không hiển thị lỗi "không khớp".
///
/// Khi nào nên tái sử dụng: form đăng ký và form đặt lại mật khẩu — bất cứ chỗ
/// nào cần xác nhận mật khẩu, luôn đi kèm một `PasswordInput` phía trên.
class ConfirmPasswordInput extends StatefulWidget {
  const ConfirmPasswordInput({super.key});

  @override
  State<ConfirmPasswordInput> createState() => _ConfirmPasswordInputState();
}

class _ConfirmPasswordInputState extends State<ConfirmPasswordInput> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthFormBloc, AuthFormState>(
      // Chỉ rebuild khi chính giá trị confirmPassword đổi: tránh TextField bị
      // dựng lại (mất con trỏ) mỗi lần một field khác của form thay đổi.
      buildWhen: (previous, current) => previous.confirmPassword != current.confirmPassword,
      builder: (context, state) {
        return TextField(
          onChanged: (confirmPassword) => context.read<AuthFormBloc>().add(ConfirmPasswordChanged(confirmPassword)),
          obscureText: _obscured,
          decoration: InputDecoration(
            hintText: 'Nhập lại mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              icon: Icon(_obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscured = !_obscured),
            ),
          ),
        );
      },
    );
  }
}
