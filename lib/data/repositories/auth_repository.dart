import 'dart:async';

import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/services/auth_service.dart';
import 'package:fe/data/services/local_storage_service.dart';

/// Trạng thái đăng nhập mà UI lắng nghe.
/// [unknown] là giá trị khởi tạo trước khi đọc xong storage.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Nguồn sự thật duy nhất về trạng thái đăng nhập của app.
///
/// Ghép [AuthService] (gọi API) với [LocalStorageService] (token/user lưu
/// máy) và phát [AuthStatus] qua stream [status] để `AuthBloc` / router lắng
/// nghe. Mọi thay đổi phiên đăng nhập phải đi qua đây để stream không lệch
/// với storage.
///
/// Được khởi tạo và cung cấp ở `lib/core/di/app_dependencies.dart`.
class AuthRepository {
  final AuthService _authService;
  final LocalStorageService _localStorageService;
  final _controller = StreamController<AuthStatus>();

  AuthRepository({
    required AuthService authService,
    required LocalStorageService localStorageService,
    }) : 
      _authService = authService,
      _localStorageService = localStorageService;

  Stream<AuthStatus> get status async* {
    await Future<void>.delayed(const Duration(seconds: 1));

    final user = await _localStorageService.getUser();
    if (user != null) {
      yield AuthStatus.authenticated;
    } else {
      yield AuthStatus.unauthenticated;
    }
    yield* _controller.stream;
  }

  Future<void> loginWithGoogle({String? idToken}) async {
    final user = await _authService.loginWithGoogle(idToken: idToken);
    if (user != null) {
      _controller.add(AuthStatus.authenticated);
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final user = await _authService.login(email: email, password: password);
      if (user != null) {
        await _localStorageService.saveUser(user);
        _controller.add(AuthStatus.authenticated);
      } else {
        _controller.add(AuthStatus.unauthenticated);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> register({required String name, required String email, required String password}) async {
    return await _authService.register(name: name, email: email, password: password);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _authService.sendPasswordResetEmail(email: email);
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    final success = await _authService.verifyOtp(email: email, otp: otp);
    if (success) {
      final user = await _localStorageService.getUser();
      if (user != null) {
        _controller.add(AuthStatus.authenticated);
      }
    }
    return success;
  }
  
  Future<void> resendOtp({required String email}) async {
    await _authService.resendOtp(email: email);
  }

  Future<void> resetPassword({required String newPassword}) async {
    await _authService.resetPassword(newPassword: newPassword);
  }

  /// Gọi POST /auth/refresh. Trả về access_token mới hoặc null nếu thất bại.
  /// Khi thất bại: xóa token, emit unauthenticated → app redirect về login.
  Future<String?> refreshToken() async {
    final refreshToken = await _localStorageService.getRefreshToken();
    if (refreshToken == null) {
      await logout();
      return null;
    }
    final newToken = await _authService.refreshAccessToken(refreshToken);
    if (newToken == null) {
      await logout();
      return null;
    }
    return newToken;
  }

  Future<void> logout() async {
    await _authService.logout();
    await _localStorageService.clearAll();
    _controller.add(AuthStatus.unauthenticated);
  }

  Future<User?> getCurrentUser() async {
    return _localStorageService.getUser();
  }

  void dispose() => _controller.close();
}