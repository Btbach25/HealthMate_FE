import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConfirmPasswordInput extends StatelessWidget {
  const ConfirmPasswordInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthFormBloc, AuthFormState>(
      buildWhen: (previous, current) => previous.confirmPassword != current.confirmPassword,
      builder: (context, state) {
        return TextField(
          onChanged: (confirmPassword) => context.read<AuthFormBloc>().add(ConfirmPasswordChanged(confirmPassword)),
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Nhập lại mật khẩu',
            prefixIcon: Icon(Icons.lock_outline),
            suffixIcon: Icon(Icons.visibility_off_outlined), // Placeholder
          ),
        );
      },
    );
  }
}