// lib/main.dart
import 'dart:async' show unawaited;
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
import 'package:fe/data/services/fcm_debug_service.dart';
import 'package:fe/data/services/health_ws_service.dart';
import 'package:fe/data/services/readiness_service.dart';
import 'package:fe/data/services/stress_service.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
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
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[Firebase] Skip background init: $e');
      return;
    }
  }
  debugPrint('[FCM] Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);

  // Load .env (web + mobile dùng chung — BE đã host nên cùng base URL)
  var envLoaded = false;
  try {
    await dotenv.load(fileName: '.env');
    envLoaded = true;
    debugPrint(
      '[env] BASE_URL=${dotenv.env['BASE_URL'] ?? '(empty — Auth/API dùng fallback cổng 8080)'}',
    );
  } catch (e) {
    debugPrint('Không tìm thấy file .env, sử dụng giá trị mặc định');
  }

  final envMap = envLoaded ? dotenv.env : const <String, String>{};

  // Web requires FirebaseOptions for default app.
  // If not configured yet, keep app running without Firebase features.
  final hasFirebaseWebConfig =
      (envMap['FIREBASE_API_KEY'] ?? '').isNotEmpty &&
      (envMap['FIREBASE_APP_ID'] ?? '').isNotEmpty &&
      (envMap['FIREBASE_MESSAGING_SENDER_ID'] ?? '').isNotEmpty &&
      (envMap['FIREBASE_PROJECT_ID'] ?? '').isNotEmpty;
  try {
    if (Firebase.apps.isEmpty) {
      if (kIsWeb && !hasFirebaseWebConfig) {
        debugPrint(
          '[Firebase] Missing web Firebase config in .env, skip initializeApp().',
        );
      } else {
        await Firebase.initializeApp();
      }
    }
  } catch (e) {
    debugPrint('[Firebase] initializeApp failed, continue without Firebase: $e');
  }
  if (Firebase.apps.isNotEmpty) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Debug only: print FCM token for push notification testing.
  // Không được chặn startup vì có thể làm app đứng ở splash native.
  unawaited(FcmDebugService.printTokenOnStartup());

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
  final stressService = StressService(
    localStorage,
    onRefresh: authRepository.refreshToken,
  );

  final fcmService = FcmService(localStorage);
  fcmService.init(); // fire-and-forget: xin permission + gửi token nếu đã login

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
      stressService: stressService,
      fcmService: fcmService,
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
  final StressService _stressService;
  final FcmService _fcmService;

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
    required StressService stressService,
    required FcmService fcmService,
  }) : _authRepository = authRepository,
       _homeRepository = homeRepository,
       _statsRepository = statsRepository,
       _familyRepository = familyRepository,
       _healthRepository = healthRepository,
       _userService = userService,
       _medicationRepository = medicationRepository,
       _healthWsService = healthWsService,
       _readinessService = readinessService,
       _stressService = stressService,
       _fcmService = fcmService;

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
        RepositoryProvider.value(value: _healthWsService),
        RepositoryProvider.value(value: _fcmService),
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
              _stressService,
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
        if (!mounted) return;
        if (authState.status == AuthStatus.authenticated) {
          context.read<FcmService>().registerCurrentToken();
          final userService = context.read<UserService>();
          Future<void>(() async {
            await userService.syncTimezoneAfterLogin();
          });
        } else if (authState.status == AuthStatus.unauthenticated) {
          context.read<DeviceHealthCubit>().stopPeriodicSync();
          context.read<FcmService>().unregisterToken();
        }
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
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppSize.r12)),
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppSize.r12)),
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppSize.r12)),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppSize.r12)),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppSize.r12)),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: 15),
            prefixIconColor: AppColors.textGrey,
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
