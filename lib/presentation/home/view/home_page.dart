import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin người dùng từ AuthBloc
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: <Widget>[
          IconButton(
            key: const Key('homePage_logout_iconButton'),
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Gửi sự kiện yêu cầu đăng xuất
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Chào mừng, ${user.name}!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'UserID: ${user.id}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}