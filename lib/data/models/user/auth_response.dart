import 'package:fe/core/utils/converter.dart';

import 'user.dart';

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