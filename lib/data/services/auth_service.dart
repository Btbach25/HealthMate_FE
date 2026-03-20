import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user/auth_response.dart';
import '../models/user/user.dart';
import 'package:fe/core/utils/converter.dart';

abstract class AuthService {
  Future<User?> login({required String email, required String password});
  Future<User?> loginWithGoogle({String? idToken});
  Future<void> logout();
  Future<User?> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail({required String email});
  Future<bool> verifyOtp({required String email, required String otp});
  Future<void> resendOtp({required String email});
  Future<void> resetPassword({required String newPassword});
  Future<String?> refreshAccessToken(String refreshToken);
}

class AuthApiService implements AuthService {
  final LocalStorageService _localStorage;
  static const _googleClientId = '819933666164-808gbgrfp1vjl16j3667afjkoiev5b0i.apps.googleusercontent.com';
  final _googleSignIn = GoogleSignIn(
    // Web dùng clientId, Android/iOS dùng serverClientId để lấy idToken cho BE
    clientId: kIsWeb ? _googleClientId : null,
    serverClientId: kIsWeb ? null : _googleClientId,
  );

  AuthApiService(this._localStorage);
  String get baseUrl {
    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }

    return 'http://localhost:8080/api/v1';
  }

  @override
  Future<User?> login({required String email, required String password}) async {
    try {
      final url = Uri.parse('$baseUrl/auth/app');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(body);

        await _localStorage.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken
        );

        await _localStorage.saveUser(authResponse.user);

        return authResponse.user;
      }  else {
        final errorMessage = body['error'] ?? 'Đã có lỗi xảy ra';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception('Kết nối quá chậm, vui lòng thử lại.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<User?> loginWithGoogle({String? idToken}) async {
    try {
      // Web: idToken được truyền trực tiếp từ GIS credential callback
      // Native: signIn() dùng serverClientId để nhận idToken
      if (!kIsWeb) {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        idToken = googleAuth.idToken;
      }
      if (idToken == null) throw Exception('Không lấy được Google ID token. Vui lòng thử lại.');

      final url = Uri.parse('$baseUrl/auth/google');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(body);
        await _localStorage.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        await _localStorage.saveUser(authResponse.user);
        return authResponse.user;
      } else {
        throw Exception(body['error'] ?? 'Đăng nhập Google thất bại');
      }
    } on TimeoutException {
      throw Exception('Kết nối quá chậm, vui lòng thử lại.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _localStorage.clearAll();
  }

  @override
  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic> && body['user'] != null) {
          return User.fromJson(body['user'] as Map<String, dynamic>);
        }
        return null;
      }
      else {
        String errorMessage = body['error'] ?? 'Đăng ký thất bại';

        if (errorMessage.contains("Field validation for 'Email'")) {
          errorMessage = "Email không hợp lệ.";
        } else if (errorMessage.contains(
          "user with this email already exists",
        )) {
          errorMessage = "Email này đã được sử dụng.";
        } else if (errorMessage.contains("associated with a Google account")) {
          errorMessage =
              "Email này đã liên kết với tài khoản Google. Vui lòng đăng nhập bằng Google.";
        }

        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception('Kết nối quá chậm, vui lòng thử lại.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    // TODO: Gọi API
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      final url = Uri.parse('$baseUrl/auth/otp/verify');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // If backend returns access_token/refresh_token and user, save them
        if (body is Map<String, dynamic>) {
          if (body.containsKey('access_token') && body.containsKey('refresh_token')) {
            await _localStorage.saveTokens(
              accessToken: cvToString(body['access_token']),
              refreshToken: cvToString(body['refresh_token']),
            );
          }
          if (body.containsKey('user') && body['user'] is Map<String, dynamic>) {
            final user = User.fromJson(body['user'] as Map<String, dynamic>);
            await _localStorage.saveUser(user);
          }
        }

        return true;
      } else {
        throw Exception(body['error'] ?? 'OTP không chính xác');
      }
    } on TimeoutException {
      throw Exception('Kết nối quá chậm, vui lòng thử lại.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> resendOtp({required String email}) async {
    try {
      final url = Uri.parse('$baseUrl/auth/otp/resend');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Không thể gửi lại OTP');
      }
    } on TimeoutException {
      throw Exception('Kết nối quá chậm, vui lòng thử lại.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    // TODO: Gọi API
    throw UnimplementedError();
  }

  @override
  Future<String?> refreshAccessToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final newToken = body['access_token'] as String?;
        if (newToken != null) {
          await _localStorage.saveAccessToken(newToken);
          debugPrint('[Auth] Token refreshed successfully');
          return newToken;
        }
      }
      debugPrint('[Auth] refreshAccessToken failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('[Auth] refreshAccessToken error: $e');
    }
    return null;
  }
}
