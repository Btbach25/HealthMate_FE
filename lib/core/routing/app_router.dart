// lib/core/routing/app_router.dart
import 'dart:async';

import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/main_tabs/shell/view/app_shell.dart';

import 'package:fe/presentation/main_tabs/family_page.dart';
import 'package:fe/presentation/main_tabs/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../presentation/auth/present.dart';
import '../../presentation/home/view/home_page.dart';


final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    routes: <RouteBase>[
      // --- CÁC ROUTE XÁC THỰC (BÊN NGOÀLI SHELL) ---
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
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // NHÁNH 1: TỔNG QUAN (HomePage)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/', // Đây là route mặc định duy nhất
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),

          // NHÁNH 2: GIA ĐÌNH
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/family',
                builder: (context, state) => const FamilyPage(),
              ),
            ],
          ),

          // NHÁNH 3: CHỈ SỐ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Chỉ số'))),
              ),
            ],
          ),

          // NHÁNH 4: THUỐC
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meds',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Thuốc'))),
              ),
            ],
          ),

          // NHÁNH 5: CÀI ĐẶT (Chứa nút Logout)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],

    // Logic redirect giữ nguyên
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authBloc.state.status == AuthStatus.authenticated;

      final authRoutes = [
        '/login',
        '/signup',
        '/forgot-password',
        '/otp',
        '/reset-password'
      ];
      final isGoingToAuthRoute = authRoutes.contains(state.matchedLocation);

      if (!loggedIn && !isGoingToAuthRoute) {
        return '/login';
      }

      if (loggedIn && isGoingToAuthRoute) {
        return '/';
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
  );
}

// GoRouterRefreshStream giữ nguyên
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