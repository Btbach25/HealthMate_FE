// lib/main.dart
import 'dart:math' show min;

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
import 'package:fe/data/repositories/medication_repository.dart';
import 'package:fe/data/services/api_medication_service.dart';
import 'package:fe/data/services/api_stats_service.dart';
import 'package:fe/data/services/device_health_service.dart';
import 'package:fe/data/services/health_ws_service.dart';
import 'package:fe/data/services/readiness_service.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/routing/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('vi_VN', null);

  // Load environment file. Use --dart-define=ENV=dev|prod to pick .env.dev/.env.prod
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  try {
    await dotenv.load(fileName: '.env.$env');
    debugPrint(
      '[env] ENV=$env BASE_URL=${dotenv.env['BASE_URL'] ?? '(empty — Auth/API dùng fallback cổng 8080)'}',
    );
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
  final statsService = ApiStatsService(
    localStorage,
    onRefresh: authRepository.refreshToken,
  );
  final statsRepository = StatsRepository(statsService: statsService);
  final apiClient = ApiClientImpl(
    localStorageService: localStorage,
    onRefreshToken: () async {
      final token = await authRepository.refreshToken();
      return token != null;
    },
  );
  final familyService = ApiFamilyService(apiClient: apiClient);
  final familyRepository = FamilyRepository(familyService: familyService);
  final userService = ApiUserService(apiClient: apiClient);
  final healthService = HealthService(
    localStorage,
    onRefresh: authRepository.refreshToken,
  );
  final healthRepository = HealthRepository(service: healthService);
  final medicationService = ApiMedicationService(apiClient: apiClient);
  final medicationRepository = MedicationRepository(service: medicationService);

  final healthWsService = HealthWsService(
    localStorage,
    onRefresh: authRepository.refreshToken,
  );
  final readinessService = ReadinessService(
    localStorage,
    onRefresh: authRepository.refreshToken,
  );

  // Init FCM sau khi user đã login (token sẽ tự gửi sau khi có access token)
  FcmService(localStorage).init();

  runApp(
    MyApp(
      authRepository: authRepository,
      homeRepository: homeRepository,
      statsRepository: statsRepository,
      familyRepository: familyRepository,
      healthRepository: healthRepository,
      userService: userService,
      medicationRepository: medicationRepository,
      healthWsService: healthWsService,
      readinessService: readinessService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepository _authRepository;
  final HomeRepository _homeRepository;
  final StatsRepository _statsRepository;
  final FamilyRepository _familyRepository;
  final HealthRepository _healthRepository;
  final ApiUserService _userService;
  final MedicationRepository _medicationRepository;
  final HealthWsService _healthWsService;
  final ReadinessService _readinessService;

  const MyApp({
    super.key,
    required AuthRepository authRepository,
    required HomeRepository homeRepository,
    required StatsRepository statsRepository,
    required FamilyRepository familyRepository,
    required HealthRepository healthRepository,
    required ApiUserService userService,
    required MedicationRepository medicationRepository,
    required HealthWsService healthWsService,
    required ReadinessService readinessService,
  }) : _authRepository = authRepository,
       _homeRepository = homeRepository,
       _statsRepository = statsRepository,
       _familyRepository = familyRepository,
       _healthRepository = healthRepository,
       _userService = userService,
       _medicationRepository = medicationRepository,
       _healthWsService = healthWsService,
       _readinessService = readinessService;

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
        RepositoryProvider.value(value: _medicationRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: _authRepository),
          ),
          BlocProvider(
            create: (_) => FamilyBloc(familyRepository: _familyRepository),
          ),
          // Tạo sớm ở app level để native plugin có thể đăng ký
          // ActivityResultLauncher trước khi activity đến trạng thái STARTED.
          BlocProvider(
            create: (_) => DeviceHealthCubit(
              DeviceHealthService(),
              _healthWsService,
              _readinessService,
            ),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthBloc>();
    _router = AppRouter(authBloc: authBloc).router;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          (prev.status == AuthStatus.authenticated &&
              curr.status == AuthStatus.unauthenticated) ||
          (curr.status == AuthStatus.authenticated &&
              prev.status != AuthStatus.authenticated),
      listener: (context, authState) {
        // FamilyBloc sống cả app; khi đăng xuất/đăng nhập lại phải xóa trạng thái lỗi 401 cũ
        // (FamilyPage có thể chưa mount nên không lắng nghe được ở đó).
        context.read<FamilyBloc>().add(const ResetFamily());
      },
      child: MaterialApp.router(
        title: 'HealthMate',
        debugShowCheckedModeBanner: false,
        // Cột giữa: SizedBox không đủ — MediaQuery vẫn báo full màn hình nên Row/Scaffold vẫn giãn ngang.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          final colW = min(mq.size.width, AppSize.shellMaxWidth);
          final h = mq.size.height;
          final scoped = mq.copyWith(size: Size(colW, h));
          return ColoredBox(
            color: AppColors.background,
            child: Center(
              child: MediaQuery(
                data: scoped,
                child: SizedBox(
                  width: colW,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
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
        routerConfig: _router,
      ),
    );
  }
}
