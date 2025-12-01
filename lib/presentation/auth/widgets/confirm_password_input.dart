import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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