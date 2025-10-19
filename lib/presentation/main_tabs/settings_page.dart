import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          onPressed: () {
            context.read<AuthBloc>().add(AuthLogoutRequested());
          },
        ),
      ),
    );
  }
}