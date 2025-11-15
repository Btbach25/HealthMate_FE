import '../models/user/user.dart';
import '../enums/user_role.dart';
import '../enums/user_status.dart';
import '../enums/login_provider.dart';

abstract class AuthService {
  Future<User?> login({required String email, required String password});
  Future<void> logout();
  Future<void> register({required String name, required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<bool> verifyOtp({required String otp});
  Future<void> resetPassword({required String newPassword});
}

class MockAuthService implements AuthService {
  // 1. Định nghĩa một đối tượng User mock
  final User _mockAdminUser = User(
    id: 'c7b5a32a-1b4e-4b8d-9c3a-3f3a2b1b9c0d',
    name: 'Nguyen Van Minh',
    email: 'admin@gmail.com',
    picture: null,
    role: UserRole.admin,
    status: UserStatus.verified,
    provider: LoginProvider.email,
    googleId: null,
    passwordHash: 'a_very_secure_mock_hash',
    createdAt: DateTime(2023, 10, 1),
    updatedAt: DateTime.now(),
  );

  User? _currentUser;

  @override
  Future<User?> login({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 1));

    // 2. So sánh với dữ liệu từ user mock
    if (email == _mockAdminUser.email && password == 'admin') {
      _currentUser = _mockAdminUser; // 3. Gán đối tượng đã được tạo sẵn
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
    print('User registered: $name, $email');
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(seconds: 2));
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
  Future<void> resetPassword({required String newPassword}) async {
    await Future.delayed(const Duration(seconds: 1));
    print('Password has been successfully reset to: $newPassword');
  }
}