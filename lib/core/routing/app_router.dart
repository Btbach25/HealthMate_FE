import 'dart:async';

// Enum AuthStatus nằm ở auth_repository chứ không phải trong AuthBloc.
import 'package:fe/data/repositories/auth_repository.dart' show AuthStatus;
import 'package:fe/data/repositories/medication_repository.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/auth/present.dart';
import 'package:fe/presentation/details/view/stats_page.dart';
import 'package:fe/presentation/family/view/create_group_page.dart';
import 'package:fe/presentation/family/view/family_group_management_page.dart';
import 'package:fe/presentation/family/view/family_page.dart';
import 'package:fe/presentation/family/view/group_details_page.dart';
import 'package:fe/presentation/home/view/home_page.dart';
import 'package:fe/presentation/main_tabs/settings_page.dart';
import 'package:fe/presentation/main_tabs/shell/view/app_shell.dart';
import 'package:fe/presentation/medications/bloc/medication_bloc.dart';
import 'package:fe/presentation/medications/view/medication_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Navigator gốc — dùng cho dialog/bottom-sheet cần nằm trên cả shell
/// (`Navigator.of(context, rootNavigator: true)`).
final rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    routes: <RouteBase>[
      // --- ROUTE XÁC THỰC: nằm NGOÀI shell nên không có bottom nav ---
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (BuildContext context, GoRouterState state) =>
            const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          // `state.extra` chuẩn là Map { email: String, flow: OtpFlow }.
          // Vẫn chấp nhận `flow` dạng String và `extra` là String thuần
          // (chỉ email) để không vỡ các lời gọi điều hướng cũ.
          final extra = state.extra;
          String email = '';
          OtpFlow flow = OtpFlow.login;
          if (extra is Map<String, Object?>) {
            email = (extra['email'] as String?) ?? '';
            final f = extra['flow'];
            if (f is OtpFlow) flow = f;
            if (f is String) {
              switch (f) {
                case 'signup':
                  flow = OtpFlow.signup;
                  break;
                case 'forgot':
                  flow = OtpFlow.forgot;
                  break;
                default:
                  flow = OtpFlow.login;
              }
            }
          } else if (extra is String) {
            email = extra;
          }
          return OtpPage(email: email, flow: flow);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (BuildContext context, GoRouterState state) =>
            const ResetPasswordPage(),
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
                routes: [
                  GoRoute(
                    path: 'manage',
                    builder: (context, state) =>
                        const FamilyGroupManagementPage(),
                  ),
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateGroupPage(),
                  ),
                  GoRoute(
                    path: 'group/:groupId',
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      return GroupDetailsPage(groupId: groupId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // NHÁNH 3: CHỈ SỐ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsPage(),
              ),
            ],
          ),

          // NHÁNH 4: THUỐC — MedicationBloc (quét đơn mở bằng dialog từ MedicationView)
          StatefulShellBranch(
            routes: [
              ShellRoute(
                builder: (context, state, child) {
                  return BlocProvider(
                    create: (c) => MedicationBloc(
                      repository: c.read<MedicationRepository>(),
                    )..add(const FetchMedications()),
                    child: child,
                  );
                },
                routes: [
                  GoRoute(
                    path: '/meds',
                    builder: (context, state) => const MedicationView(),
                  ),
                ],
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

    // Gác cổng đăng nhập: chưa đăng nhập → ép về /login;
    // đã đăng nhập mà còn ở màn auth → đẩy về trang chủ.
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authBloc.state.status == AuthStatus.authenticated;

      final authRoutes = [
        '/login',
        '/signup',
        '/forgot-password',
        '/otp',
        '/reset-password',
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

/// Cầu nối Stream (AuthBloc) → Listenable cho `GoRouter.refreshListenable`,
/// để router chạy lại `redirect` mỗi khi trạng thái đăng nhập đổi.
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
