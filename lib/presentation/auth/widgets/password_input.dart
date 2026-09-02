import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ô nhập mật khẩu có nút ẩn/hiện, tự đẩy giá trị vào `AuthFormBloc`.
///
/// Không nhận tham số: widget tự lấy bloc qua `context.read`, nên **bắt buộc**
/// phải đặt bên dưới một `BlocProvider<AuthFormBloc>` (mọi màn auth đều có).
///
/// Trạng thái ẩn/hiện là state cục bộ của widget, cố ý không đưa vào bloc —
/// nó chỉ là chuyện hiển thị, không thuộc dữ liệu form.
///
/// Khi nào nên tái sử dụng: mọi form cần nhập mật khẩu chính (đăng nhập, đăng
/// ký, đặt lại mật khẩu). Với ô "nhập lại mật khẩu" dùng `ConfirmPasswordInput`
/// vì nó bắn event khác.
class PasswordInput extends StatefulWidget {
  const PasswordInput({super.key});

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthFormBloc, AuthFormState>(
      // Chỉ rebuild khi chính giá trị password đổi: tránh TextField bị dựng lại
      // (mất con trỏ) mỗi lần state form đổi vì một field khác.
      buildWhen: (previous, current) => previous.password != current.password,
      builder: (context, state) {
        return TextField(
          onChanged: (password) =>
              context.read<AuthFormBloc>().add(PasswordChanged(password)),
          obscureText: _obscured,
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              icon: Icon(
                _obscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _obscured = !_obscured),
            ),
          ),
        );
      },
    );
  }
}
