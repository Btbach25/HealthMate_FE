import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fe/data/core/api_client.dart';
import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/services/local_storage_service.dart';

/// Implementation of ApiClient with token from LocalStorage and baseUrl from .env.
/// Khi gặp 401, nếu [onRefreshToken] được cung cấp và request không phải /auth/refresh,
/// gọi refresh để lấy access_token mới rồi retry 1 lần.
class ApiClientImpl extends ApiClient {
  final LocalStorageService _localStorageService;
  final String? _baseUrlOverride;
  final Future<bool> Function()? onRefreshToken;

  ApiClientImpl({
    required LocalStorageService localStorageService,
    String? baseUrlOverride,
    this.onRefreshToken,
  })  : _localStorageService = localStorageService,
        _baseUrlOverride = baseUrlOverride;

  @override
  String get baseUrl {
    if (_baseUrlOverride != null && _baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }
    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://localhost:8080';
  }

  @override
  Future<String?> getAuthToken() async {
    return _localStorageService.getAccessToken();
  }

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
