import 'package:fe/data/enums/user_status.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/services/auth_service.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

/// [AuthService] giả lập cho chế độ DEMO — **không gọi API nào**.
///
/// Đăng nhập bằng tài khoản demo:
/// - Email: `demo@healthmate.vn` (không phân biệt hoa thường)
/// - Mật khẩu: `demo1234`
/// - Mã OTP (mọi luồng xác thực): `123456`
///
/// Token và user giả vẫn được ghi vào [LocalStorageService] y như
/// `AuthApiService`, nhờ vậy auth-guard của router và `AuthRepository.status`
/// hoạt động đúng như chạy thật.
class MockAuthService implements AuthService {
  final LocalStorageService _localStorage;

  MockAuthService(this._localStorage);

  /// Token giả — chỉ để router thấy "đã đăng nhập".
  static const String _accessToken = 'demo-access-token';
  static const String _refreshToken = 'demo-refresh-token';

  /// Email/tên của phiên đăng ký gần nhất, dùng khi xác thực OTP xong.
  String? _pendingEmail;
  String? _pendingName;

  /// Giả lập độ trễ mạng để UI kịp hiển thị trạng thái loading.
  Future<void> _delay([int milliseconds = 450]) =>
      Future<void>.delayed(Duration(milliseconds: milliseconds));

  Future<User> _signIn(User user) async {
    await _localStorage.saveTokens(
      accessToken: _accessToken,
      refreshToken: _refreshToken,
    );
    await _localStorage.saveUser(user);
    await _localStorage.saveAllergies(user.allergies);
    debugPrint('[MockAuth] Đăng nhập DEMO thành công: ${user.email}');
    return user;
  }

  @override
  Future<User?> login({required String email, required String password}) async {
    await _delay(600);

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      throw Exception('Vui lòng nhập email và mật khẩu.');
    }
    if (normalizedEmail != MockUsers.demoEmail.toLowerCase() ||
        normalizedPassword != MockUsers.demoPassword) {
      throw Exception(
        'Email hoặc mật khẩu không đúng. Chế độ DEMO chỉ chấp nhận '
        '${MockUsers.demoEmail} / ${MockUsers.demoPassword}.',
      );
    }

    return _signIn(MockUsers.demoUser);
  }

  @override
  Future<User?> loginWithGoogle({String? idToken}) async {
    await _delay(700);
    // Demo không mở popup Google, luôn trả về chính tài khoản demo.
    return _signIn(MockUsers.demoUser);
  }

  @override
  Future<void> logout() async {
    await _delay(200);
    await _localStorage.clearAll();
    debugPrint('[MockAuth] Đã đăng xuất khỏi phiên DEMO');
  }

  @override
  Future<String?> refreshAccessToken(String refreshToken) async {
    await _delay(200);
    await _localStorage.saveAccessToken(_accessToken);
    return _accessToken;
  }

  @override
  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _delay(600);

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Email không hợp lệ.');
    }
    if (password.trim().length < 6) {
      throw Exception('Mật khẩu phải có ít nhất 6 ký tự.');
    }

    _pendingEmail = normalizedEmail;
    _pendingName = name.trim().isEmpty ? 'Người dùng DEMO' : name.trim();

    // Trả về user chưa xác thực để demo được luôn màn hình nhập OTP.
    final now = DateTime.now();
    return MockUsers.demoUser.copyWith(
      id: 'demo-user-new',
      email: normalizedEmail,
      name: _pendingName,
      status: UserStatus.unverified,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _delay(500);
    if (email.trim().isEmpty) {
      throw Exception('Vui lòng nhập email để nhận mã khôi phục.');
    }
    _pendingEmail = email.trim().toLowerCase();
    debugPrint(
      '[MockAuth] Mã khôi phục DEMO là ${MockUsers.demoOtp} (không gửi email thật)',
    );
  }

  @override
  Future<bool> verifyOtp({required String email, required String otp}) async {
    await _delay(500);

    final normalizedOtp = otp.trim().replaceAll(RegExp(r'\D'), '');
    if (normalizedOtp.length != 6) {
      throw Exception('Mã OTP phải đủ 6 chữ số.');
    }
    if (normalizedOtp != MockUsers.demoOtp) {
      throw Exception(
        'Mã OTP không đúng. Ở chế độ DEMO, mã xác thực luôn là '
        '${MockUsers.demoOtp}.',
      );
    }

    final verifiedEmail = email.trim().toLowerCase().isNotEmpty
        ? email.trim().toLowerCase()
        : (_pendingEmail ?? MockUsers.demoEmail);

    final now = DateTime.now();
    final user = verifiedEmail == MockUsers.demoEmail.toLowerCase()
        ? MockUsers.demoUser
        : MockUsers.demoUser.copyWith(
            id: 'demo-user-new',
            email: verifiedEmail,
            name: _pendingName ?? 'Người dùng DEMO',
            status: UserStatus.verified,
            createdAt: now,
            updatedAt: now,
          );

    await _signIn(user);
    return true;
  }

  @override
  Future<void> resendOtp({required String email}) async {
    await _delay(400);
    if (email.trim().isEmpty) {
      throw Exception('Thiếu email. Vui lòng quay lại đăng nhập và thử lại.');
    }
    _pendingEmail = email.trim().toLowerCase();
    debugPrint(
      '[MockAuth] Đã "gửi lại" OTP DEMO: ${MockUsers.demoOtp}',
    );
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    await _delay(500);
    if (newPassword.trim().length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }
    debugPrint(
      '[MockAuth] Đặt lại mật khẩu DEMO thành công (dữ liệu không được lưu).',
    );
  }
}
