import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      buildWhen: (previous, current) => previous.password != current.password,
      builder: (context, state) {
        return TextField(
          onChanged: (password) => context.read<AuthFormBloc>().add(PasswordChanged(password)),
          obscureText: _obscured,
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
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