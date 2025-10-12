import '../models/user.dart';

abstract class AuthService {
  Future<User?> login({required String email, required String password});
  Future<void> logout();
  Future<void> register({required String name, required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<bool> verifyOtp({required String otp});
  Future<void> resetPassword({required String newPassword});
}

class MockAuthService implements AuthService {
  User? _currentUser;

  @override
  Future<User?> login({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email == 'admin@gmail.com' && password == 'admin') {
      _currentUser = const User(id: '1', name: 'Flutter Developer');
      return _currentUser;
    }
    throw Exception('Email hoặc mật khẩu không đúng');
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = null;
  }

  @override
  Future<void> register({required String name, required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'exist@gmail.com') {
      throw Exception('Email này đã được sử dụng.');
    }
    // Giả lập đăng ký thành công
    print('User registered: $name, $email');
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(seconds: 2));
    // Giả lập gửi email thành công
    print('Password reset email sent to: $email');
  }

  @override
  Future<bool> verifyOtp({required String otp}) async {
    await Future.delayed(const Duration(seconds: 2));
    if (otp == '123456') {
      return true;
    }
    return false;
  }

  @override
  Future<void> resetPassword({required String newPassword}) async { // <-- THÊM TRIỂN KHAI
    await Future.delayed(const Duration(seconds: 1));
    print('Password has been successfully reset to: $newPassword');
  }
}