import 'package:fe/core/config/app_config.dart';
import 'package:fe/core/utils/access_token_expiry.dart';
import 'package:fe/data/core/api_client.dart';
import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/services/local_storage_service.dart';

/// [ApiClient] dùng thật trong app: lấy access token từ
/// [LocalStorageService] và base URL từ [AppConfig] (đọc `.env`).
///
/// Bổ sung hai lớp xử lý token quanh mỗi request:
/// - Chủ động: trước khi gửi, nếu token sắp hết hạn thì gọi [onRefreshToken]
///   ngay (xem [buildHeaders]) để tránh chắc chắn ăn 401.
/// - Bị động: nếu vẫn nhận 401 thì refresh rồi retry ĐÚNG MỘT LẦN.
///
/// Request tới `/auth/refresh` được loại trừ khỏi retry ([_shouldSkipRefresh])
/// — refresh token hỏng mà vẫn retry sẽ thành vòng lặp vô hạn.
///
/// Được đăng ký ở `lib/core/di/app_dependencies.dart` (composition root).
class ApiClientImpl extends ApiClient {
  final LocalStorageService _localStorageService;
  final String? _baseUrlOverride;
  final Future<bool> Function()? onRefreshToken;

  ApiClientImpl({
    required LocalStorageService localStorageService,
    String? baseUrlOverride,
    this.onRefreshToken,
  }) : _localStorageService = localStorageService,
       _baseUrlOverride = baseUrlOverride;

  @override
  String get baseUrl {
    if (_baseUrlOverride != null && _baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }
    return AppConfig.apiBaseUrl;
  }

  @override
  Future<String?> getAuthToken() async {
    return _localStorageService.getAccessToken();
  }

  @override
  Future<Map<String, String>> buildHeaders({
    Map<String, String>? additionalHeaders,
    bool includeAuth = true,
  }) async {
    if (includeAuth && onRefreshToken != null) {
      final token = await getAuthToken();
      if (shouldProactivelyRefreshAccessToken(token)) {
        await onRefreshToken!();
      }
    }
    return super.buildHeaders(
      additionalHeaders: additionalHeaders,
      includeAuth: includeAuth,
    );
  }

  /// Chặn refresh-rồi-retry cho chính endpoint refresh (tránh đệ quy vô hạn).
  bool _shouldSkipRefresh(String endpoint) =>
      endpoint.contains('auth/refresh') || endpoint.contains('/auth/refresh');

  @override
  Future<T> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      return await super.get<T>(
        endpoint,
        queryParameters: queryParameters,
        headers: headers,
        parser: parser,
        includeAuth: includeAuth,
      );
    } on UnauthorizedException {
      if (!_shouldSkipRefresh(endpoint) &&
          onRefreshToken != null &&
          await onRefreshToken!()) {
        return await super.get<T>(
          endpoint,
          queryParameters: queryParameters,
          headers: headers,
          parser: parser,
          includeAuth: includeAuth,
        );
      }
      rethrow;
    }
  }

  @override
  Future<T> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      return await super.post<T>(
        endpoint,
        body: body,
        headers: headers,
        parser: parser,
        includeAuth: includeAuth,
      );
    } on UnauthorizedException {
      if (!_shouldSkipRefresh(endpoint) &&
          onRefreshToken != null &&
          await onRefreshToken!()) {
        return await super.post<T>(
          endpoint,
          body: body,
          headers: headers,
          parser: parser,
          includeAuth: includeAuth,
        );
      }
      rethrow;
    }
  }

  @override
  Future<T> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      return await super.put<T>(
        endpoint,
        body: body,
        headers: headers,
        parser: parser,
        includeAuth: includeAuth,
      );
    } on UnauthorizedException {
      if (!_shouldSkipRefresh(endpoint) &&
          onRefreshToken != null &&
          await onRefreshToken!()) {
        return await super.put<T>(
          endpoint,
          body: body,
          headers: headers,
          parser: parser,
          includeAuth: includeAuth,
        );
      }
      rethrow;
    }
  }

  @override
  Future<T> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      return await super.delete<T>(
        endpoint,
        headers: headers,
        parser: parser,
        includeAuth: includeAuth,
      );
    } on UnauthorizedException {
      if (!_shouldSkipRefresh(endpoint) &&
          onRefreshToken != null &&
          await onRefreshToken!()) {
        return await super.delete<T>(
          endpoint,
          headers: headers,
          parser: parser,
          includeAuth: includeAuth,
        );
      }
      rethrow;
    }
  }
}
