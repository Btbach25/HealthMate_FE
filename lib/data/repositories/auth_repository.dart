import 'dart:async';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/services/local_storage_service.dart';

import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

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
    await Future<void>.delayed(const Duration(seconds: 1)); // Giả lập kiểm tra

    final user = await _localStorageService.getUser();
    if (user != null) {
      yield AuthStatus.authenticated;
    } else {
      yield AuthStatus.unauthenticated;
    }
    yield* _controller.stream;
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
    await _localStorageService.clearUser();
    _controller.add(AuthStatus.unauthenticated);
  }

  Future<User?> getCurrentUser() async {
    return _localStorageService.getUser();
  }

  void dispose() => _controller.close();
}