// lib/main.dart
import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/repositories/home_repository.dart';
import 'package:fe/data/repositories/stats_repository.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/data/services/mock_home_service.dart';
import 'package:fe/data/services/mock_stats_service.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/routing/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_service.dart';

void main() {
  final authService = MockAuthService();
  final localStorageService = LocalStorageService();
  final authRepository = AuthRepository(
    authService: authService,
    localStorageService: localStorageService,
  );
  final homeService = MockHomeService();
  final homeRepository = HomeRepository(homeService: homeService);
  final statsService = MockStatsService();
  final statsRepository = StatsRepository(statsService: statsService);

  runApp(MyApp(authRepository: authRepository, homeRepository: homeRepository,statsRepository: statsRepository,));
}

class MyApp extends StatelessWidget {
  final AuthRepository _authRepository;
  final HomeRepository _homeRepository;
  final StatsRepository _statsRepository;

  const MyApp({
    super.key,
    required AuthRepository authRepository,
    required HomeRepository homeRepository,
    required StatsRepository statsRepository,
  }) : _authRepository = authRepository,
       _homeRepository = homeRepository,
       _statsRepository = statsRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _homeRepository),
        RepositoryProvider.value(value: _statsRepository),
      ],
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
    final authBloc = context.read<AuthBloc>();
    final router = AppRouter(authBloc: authBloc).router;

    return MaterialApp.router(
      title: 'HealthMate App',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(primary: AppColors.primary),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSize.r12)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.inputBackground,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ),
      routerConfig: router,
    );
  }
}
