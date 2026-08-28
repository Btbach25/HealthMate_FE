import 'dart:math' show min;

import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/di/app_dependencies.dart';
import 'package:fe/core/routing/app_router.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_theme.dart';
import 'package:fe/data/services/fcm_service.dart';
import 'package:fe/data/services/health_ws_service.dart';
import 'package:fe/data/services/user_service.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/auth/bloc/auth_state.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/bloc/family_event.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Root widget: cắm dependency vào cây widget rồi bàn giao cho [_AppView].
///
/// Chỉ những bloc **sống suốt vòng đời app** mới đặt ở đây; bloc theo màn hình
/// phải được tạo trong `view/<feature>_page.dart` để tự huỷ khi rời màn hình.
class HealthMateApp extends StatelessWidget {
  const HealthMateApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: dependencies.authRepository),
        RepositoryProvider.value(value: dependencies.homeRepository),
        RepositoryProvider.value(value: dependencies.statsRepository),
        RepositoryProvider.value(value: dependencies.familyRepository),
        RepositoryProvider.value(value: dependencies.healthRepository),
        RepositoryProvider.value(value: dependencies.medicationRepository),
        RepositoryProvider<UserService>.value(value: dependencies.userService),
        RepositoryProvider<HealthWsService>.value(
          value: dependencies.healthWsService,
        ),
        RepositoryProvider<FcmService>.value(value: dependencies.fcmService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: dependencies.authRepository),
          ),
          BlocProvider(
            create: (_) =>
                FamilyBloc(familyRepository: dependencies.familyRepository),
          ),
          // Tạo sớm ở app level để native plugin kịp đăng ký
          // ActivityResultLauncher trước khi Activity vào trạng thái STARTED.
          BlocProvider(
            create: (_) => DeviceHealthCubit(
              dependencies.deviceHealthService,
              dependencies.healthWsService,
              dependencies.readinessService,
              dependencies.stressService,
            ),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Router phải dựng một lần duy nhất: tạo lại trong build() sẽ reset stack
    // điều hướng mỗi lần rebuild.
    _router = AppRouter(authBloc: context.read<AuthBloc>()).router;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: _isLoginOrLogoutTransition,
      listener: _onAuthChanged,
      child: MaterialApp.router(
        title: 'HealthMate',
        debugShowCheckedModeBanner: false,
        builder: _buildPhoneWidthShell,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }

  bool _isLoginOrLogoutTransition(AuthState prev, AuthState curr) =>
      (prev.status == AuthStatus.authenticated &&
          curr.status == AuthStatus.unauthenticated) ||
      (curr.status == AuthStatus.authenticated &&
          prev.status != AuthStatus.authenticated);

  void _onAuthChanged(BuildContext context, AuthState state) {
    if (!mounted) return;

    if (state.status == AuthStatus.authenticated) {
      context.read<FcmService>().registerCurrentToken();
      context.read<UserService>().syncTimezoneAfterLogin();
    } else if (state.status == AuthStatus.unauthenticated) {
      context.read<DeviceHealthCubit>().stopPeriodicSync();
      context.read<FcmService>().unregisterToken();
    }

    // FamilyBloc sống suốt vòng đời app nên phải tự dọn state lỗi 401 cũ ở đây:
    // FamilyPage có thể chưa mount nên không lắng nghe được sự kiện này.
    context.read<FamilyBloc>().add(const ResetFamily());
  }

  /// Khoá bề rộng nội dung ở [AppSize.shellMaxWidth] để layout mobile không bị
  /// kéo giãn trên web/desktop.
  ///
  /// Chỉ bọc `SizedBox` là không đủ: `MediaQuery` vẫn báo kích thước màn hình
  /// thật nên `Row`/`Scaffold` bên trong vẫn giãn hết chiều ngang → phải
  /// override luôn `MediaQueryData.size`.
  Widget _buildPhoneWidthShell(BuildContext context, Widget? child) {
    final mediaQuery = MediaQuery.of(context);
    final width = min(mediaQuery.size.width, AppSize.shellMaxWidth);

    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: MediaQuery(
          data: mediaQuery.copyWith(
            size: Size(width, mediaQuery.size.height),
          ),
          child: SizedBox(
            width: width,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
