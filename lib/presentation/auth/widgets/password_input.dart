import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PasswordInput extends StatelessWidget {
  const PasswordInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthFormBloc, AuthFormState>(
      buildWhen: (previous, current) => previous.password != current.password,
      builder: (context, state) {
        return TextField(
          onChanged: (password) => context.read<AuthFormBloc>().add(PasswordChanged(password)),
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Nhập mật khẩu (tối thiểu)',
            prefixIcon: Icon(Icons.lock_outline),
            suffixIcon: Icon(Icons.visibility_off_outlined), // Placeholder
          ),
        );
      },
    );
  }
}