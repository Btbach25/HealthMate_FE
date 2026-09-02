import 'package:fe/data/services/local_storage_service.dart';
import 'package:http/http.dart' as http;

/// Bọc `http` để tự đính kèm access token và tự thử lại đúng MỘT lần khi
/// gặp 401.
///
/// Dùng cho repository gọi API cần đăng nhập, thay vì gọi thẳng `http.get` /
/// `http.post` rồi tự xử token ở từng chỗ.
///
/// [_onRefresh] thường là `AuthRepository.refreshToken` — truyền vào qua DI
/// chứ không import ngược `AuthRepository`, để tránh phụ thuộc vòng giữa
/// tầng repository và helper này.
///
/// ```dart
/// final helper = AuthHttpHelper(localStorage, authRepository.refreshToken);
/// final res = await helper.get(Uri.parse('$baseUrl/groups'));
/// ```
///
/// Ràng buộc cần biết:
/// * Chỉ thử lại đúng một lần. Lần thử lại mà vẫn 401 thì trả về nguyên
///   response 401 để phía gọi quyết định (thường là đăng xuất).
/// * Không có token sẵn thì KHÔNG gọi mạng, trả ngay 401 giả lập — phía gọi
///   cứ xử lý theo mã lỗi như bình thường.
/// * Mọi request timeout sau 10 giây.
class AuthHttpHelper {
  final LocalStorageService _localStorage;
  final Future<String?> Function()? _onRefresh;

  AuthHttpHelper(this._localStorage, this._onRefresh);

  /// GET kèm `Authorization: Bearer <token>`.
  Future<http.Response> get(Uri uri) => _withRetry(
    (token) => http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 10)),
  );

  /// POST kèm `Authorization` và `Content-Type: application/json`.
  ///
  /// [body] phải là chuỗi JSON đã encode sẵn (`jsonEncode(...)`), header đã
  /// khai báo là JSON nên truyền Map thô sẽ bị gửi sai định dạng.
  Future<http.Response> post(Uri uri, {Object? body}) => _withRetry(
    (token) => http
        .post(uri, headers: _headers(token), body: body)
        .timeout(const Duration(seconds: 10)),
  );

  Future<http.Response> _withRetry(
    Future<http.Response> Function(String token) fn,
  ) async {
    final token = await _localStorage.getAccessToken();
    if (token == null) return http.Response('{"error":"unauthenticated"}', 401);

    var resp = await fn(token);
    if (resp.statusCode != 401 || _onRefresh == null) return resp;

    // 401 → xin token mới rồi gọi lại đúng một lần.
    final newToken = await _onRefresh();
    if (newToken == null) return resp; // refresh thất bại → giữ nguyên 401
    return fn(newToken);
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
