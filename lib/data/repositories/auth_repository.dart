import 'dart:async';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthRepository {
  final AuthService _authService;
  final _controller = StreamController<AuthStatus>();

  AuthRepository({required AuthService authService}) : _authService = authService;

  Stream<AuthStatus> get status async* {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield AuthStatus.unauthenticated;
    yield* _controller.stream;
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final user = await _authService.login(email: email, password: password);
      if (user != null) {
        _controller.add(AuthStatus.authenticated);
      } else {
        _controller.add(AuthStatus.unauthenticated);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register({required String name, required String email, required String password}) async {
    await _authService.register(name: name, email: email, password: password);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _authService.sendPasswordResetEmail(email: email);
  }

  Future<bool> verifyOtp({required String otp}) async {
    return await _authService.verifyOtp(otp: otp);
  }

  Future<void> resetPassword({required String newPassword}) async {
    await _authService.resetPassword(newPassword: newPassword);
  }

  Future<void> logout() async {
    await _authService.logout();
    _controller.add(AuthStatus.unauthenticated);
  }

  void dispose() => _controller.close();
}