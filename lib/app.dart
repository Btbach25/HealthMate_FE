import 'dart:math' show min;

import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/di/app_dependencies.dart';
import 'package:fe/core/routing/app_router.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_scroll_behavior.dart';
import 'package:fe/core/theme/app_theme.dart';
import 'package:fe/data/repositories/auth_repository.dart' show AuthStatus;
import 'package:fe/data/services/fcm_service.dart';
import 'package:fe/data/services/health_ws_service.dart';
import 'package:fe/data/services/user_service.dart';
// AuthState và FamilyEvent là `part of` bloc tương ứng — import thẳng file
// part sẽ lỗi `import_of_non_library`. Riêng enum AuthStatus lại nằm ở
// auth_repository.dart nên phải import riêng.
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
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
            create: (_) =>
                AuthBloc(authRepository: dependencies.authRepository),
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
        // Không có dòng này thì trên web mọi vùng cuộn đều không kéo được
        // bằng chuột — xem [AppScrollBehavior].
        scrollBehavior: const AppScrollBehavior(),
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
  ///
  /// Khi cửa sổ rộng hơn cột nội dung (tức là đang chạy trên desktop), cột được
  /// bọc thêm một "khung app": nền trang xám, cột nổi lên với bo góc và đổ
  /// bóng. Nếu không, cột hẹp nằm giữa nền trắng trơn trông như layout bị vỡ
  /// chứ không phải một lựa chọn thiết kế.
  Widget _buildPhoneWidthShell(BuildContext context, Widget? child) {
    final mediaQuery = MediaQuery.of(context);
    final width = min(mediaQuery.size.width, AppSize.shellMaxWidth);
    final content = child ?? const SizedBox.shrink();

    // Còn chỗ trống hai bên → đang ở desktop/tablet ngang.
    final isFramed = mediaQuery.size.width > width + AppSize.p32;

    final column = MediaQuery(
      data: mediaQuery.copyWith(size: Size(width, mediaQuery.size.height)),
      child: SizedBox(width: width, child: content),
    );

    if (!isFramed) {
      return ColoredBox(color: AppColors.background, child: column);
    }

    return ColoredBox(
      color: AppColors.pageBackdrop,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSize.p24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSize.r24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSize.r24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 32,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: column,
            ),
          ),
        ),
      ),
    );
  }
}
