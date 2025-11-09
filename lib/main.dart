// lib/main.dart
import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/routing/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_service.dart';

void main() {
  // Khởi tạo các repository và service
  final authService = MockAuthService();
  final localStorageService = LocalStorageService();
  final authRepository = AuthRepository(authService: authService , localStorageService: localStorageService,);
  
  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository _authRepository;

  const MyApp({super.key, required AuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Widget build(BuildContext context) {
    // Cung cấp Repository cho toàn bộ ứng dụng
    return RepositoryProvider.value(
      value: _authRepository,
      // Cung cấp BLoC toàn cục cho toàn bộ ứng dụng
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository: _authRepository),
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy authBloc để truyền vào router
    final authBloc = context.read<AuthBloc>();
    final router = AppRouter(authBloc: authBloc).router;

    return MaterialApp.router(
      title: 'HealthMate App',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSize.r12)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.inputBackground,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}