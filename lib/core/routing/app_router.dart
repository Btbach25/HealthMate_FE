import 'dart:async';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../presentation/auth/present.dart';
import '../../presentation/home/view/home_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    routes: <GoRoute>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (BuildContext context, GoRouterState state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (BuildContext context, GoRouterState state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (BuildContext context, GoRouterState state) => const OtpPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (BuildContext context, GoRouterState state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const HomePage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authBloc.state.status == AuthStatus.authenticated;
      
      // Danh sách các trang người dùng có thể truy cập khi chưa đăng nhập
      final authRoutes = [
        '/login',
        '/signup',
        '/forgot-password',
        '/otp',
        '/reset-password'
      ];
      final isGoingToAuthRoute = authRoutes.contains(state.matchedLocation);

      // Kịch bản 1: Người dùng chưa đăng nhập
      // Nếu họ đang không đi đến một trang auth, chuyển hướng họ về trang đăng nhập.
      if (!loggedIn && !isGoingToAuthRoute) {
        return '/login';
      }

      // Kịch bản 2: Người dùng đã đăng nhập
      // Nếu họ đang cố gắng truy cập vào một trang auth (ví dụ: trang login),
      // chuyển hướng họ về trang chủ.
      if (loggedIn && isGoingToAuthRoute) {
        return '/';
      }

      // Trong các trường hợp còn lại, không cần chuyển hướng.
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}