// lib/main.dart
import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/repositories/family_repository.dart';
import 'package:fe/data/repositories/home_repository.dart';
import 'package:fe/data/repositories/stats_repository.dart';
import 'package:fe/data/repositories/health_repository.dart';
import 'package:fe/data/services/health_service.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/data/core/api_client_impl.dart';
import 'package:fe/data/services/api_family_service.dart';
import 'package:fe/data/services/api_user_service.dart';
import 'package:fe/data/services/user_service.dart';
import 'package:fe/data/services/mock_home_service.dart';
import 'package:fe/data/services/mock_stats_service.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/routing/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);

  // Load environment file. Use --dart-define=ENV=dev|prod to pick .env.dev/.env.prod
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  try {
    await dotenv.load(fileName: '.env.$env');
  } catch (e) {
    // File .env không tồn tại, sử dụng giá trị mặc định từ code
    debugPrint('Không tìm thấy file .env.$env, sử dụng giá trị mặc định');
  }

  final localStorage = LocalStorageService();

  final authService = AuthApiService(localStorage);
  final authRepository = AuthRepository(
    authService: authService,
    localStorageService: localStorage,
  );

  final homeService = MockHomeService();
  final homeRepository = HomeRepository(homeService: homeService);
  final statsService = MockStatsService();
  final statsRepository = StatsRepository(statsService: statsService);
  final apiClient = ApiClientImpl(
    localStorageService: localStorage,
    onRefreshToken: () => authService.refreshAccessToken(),
  );
  final familyService = ApiFamilyService(apiClient: apiClient);
  final familyRepository = FamilyRepository(familyService: familyService);
  final userService = ApiUserService(apiClient: apiClient);
  final healthService = HealthService(localStorage);
  final healthRepository = HealthRepository(service: healthService);

  runApp(MyApp(
    authRepository: authRepository,
    homeRepository: homeRepository,
    statsRepository: statsRepository,
    familyRepository: familyRepository,
    healthRepository: healthRepository,
    userService: userService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepository _authRepository;
  final HomeRepository _homeRepository;
  final StatsRepository _statsRepository;
  final FamilyRepository _familyRepository;
  final HealthRepository _healthRepository;
  final ApiUserService _userService;

  const MyApp({
    super.key,
    required AuthRepository authRepository,
    required HomeRepository homeRepository,
    required StatsRepository statsRepository,
    required FamilyRepository familyRepository,
    required HealthRepository healthRepository,
    required ApiUserService userService,
  }) : _authRepository = authRepository,
       _homeRepository = homeRepository,
       _statsRepository = statsRepository,
       _familyRepository = familyRepository,
       _healthRepository = healthRepository,
       _userService = userService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _homeRepository),
        RepositoryProvider.value(value: _statsRepository),
        RepositoryProvider.value(value: _familyRepository),
        RepositoryProvider.value(value: _healthRepository),
        RepositoryProvider<UserService>.value(value: _userService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: _authRepository),
          ),
          BlocProvider(
            create: (_) => FamilyBloc(familyRepository: _familyRepository),
          ),
        ],
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
