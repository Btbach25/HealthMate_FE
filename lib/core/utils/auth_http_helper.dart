import 'package:fe/data/services/local_storage_service.dart';
import 'package:http/http.dart' as http;

/// Wrapper quanh http với tự động refresh token khi gặp 401.
/// Truyền [onRefresh] từ AuthRepository.refreshToken.
class AuthHttpHelper {
  final LocalStorageService _localStorage;
  final Future<String?> Function()? _onRefresh;

  AuthHttpHelper(this._localStorage, this._onRefresh);

  Future<http.Response> get(Uri uri) => _withRetry(
        (token) => http
            .get(uri, headers: _headers(token))
            .timeout(const Duration(seconds: 10)),
      );

  Future<http.Response> post(Uri uri, {Object? body}) => _withRetry(
        (token) => http
            .post(uri, headers: _headers(token), body: body)
            .timeout(const Duration(seconds: 10)),
      );

  Future<http.Response> _withRetry(
      Future<http.Response> Function(String token) fn) async {
    final token = await _localStorage.getAccessToken();
    if (token == null) return http.Response('{"error":"unauthenticated"}', 401);

    var resp = await fn(token);
    if (resp.statusCode != 401 || _onRefresh == null) return resp;

    // 401 → thử refresh
    final newToken = await _onRefresh();
    if (newToken == null) return resp; // refresh thất bại, trả nguyên 401
    return fn(newToken);
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
}
