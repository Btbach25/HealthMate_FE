import 'package:fe/core/utils/converter.dart';
import 'package:fe/data/models/user/user.dart';

/// Kết quả trả về của các endpoint đăng nhập/đăng ký (`POST /auth/app`,
/// `POST /auth/google`, `POST /auth/register`): cặp token và thông tin user.
///
/// [User.empty] được dùng khi backend không kèm khối `user` trong response.
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: cvToString(json['access_token']),
      refreshToken: cvToString(json['refresh_token']),
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : User.empty(),
    );
  }
}
