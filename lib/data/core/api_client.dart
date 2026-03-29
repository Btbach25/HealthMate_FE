import 'dart:convert';
import 'package:fe/data/exceptions/api_exception.dart';
import 'package:http/http.dart' as http;

/// Base API client for making HTTP requests
/// This class provides a clean abstraction for API calls
/// and can be easily extended or replaced with different implementations
abstract class ApiClient {
  /// Base URL for the API
  String get baseUrl;

  /// Default headers for all requests
  Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Get authentication token (to be implemented by subclasses)
  Future<String?> getAuthToken();

  /// Build full URL from endpoint
  Uri buildUrl(String endpoint) {
    final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    return Uri.parse(url);
  }

  /// Build headers with authentication
  Future<Map<String, String>> buildHeaders({
    Map<String, String>? additionalHeaders,
    bool includeAuth = true,
  }) async {
    final headers = Map<String, String>.from(defaultHeaders);
    
    if (includeAuth) {
      final token = await getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }

  /// Handle HTTP response and convert to appropriate exception
  T handleResponse<T>(http.Response response, T Function(dynamic) parser) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = response.body.isEmpty ? null : json.decode(response.body);
        return parser(data);
      } catch (e) {
        throw UnknownException(
          message: 'Lỗi khi xử lý phản hồi từ máy chủ.',
          originalError: e,
        );
      }
    } else {
      throw _handleErrorResponse(response);
    }
  }

  /// Handle error response and throw appropriate exception
  ApiException _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic errorData;
    
    try {
      if (response.body.isNotEmpty) {
        errorData = json.decode(response.body);
      }
    } catch (_) {
      // Ignore JSON decode errors
    }

    final errorMessage = _extractErrorMessage(errorData) ?? 
        'Có lỗi xảy ra. Vui lòng thử lại.';

    switch (statusCode) {
      case 401:
        return UnauthorizedException(originalError: errorData);
      case 403:
        return ForbiddenException(originalError: errorData);
      case 404:
        return NotFoundException(originalError: errorData);
      case 422:
        return ValidationException(
          message: errorMessage,
          errors: _extractValidationErrors(errorData),
          originalError: errorData,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(originalError: errorData);
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return ClientException(
            message: errorMessage,
            statusCode: statusCode,
            originalError: errorData,
          );
        } else if (statusCode >= 500) {
          return ServerException(originalError: errorData);
        }
        return UnknownException(
          message: errorMessage,
          statusCode: statusCode,
          originalError: errorData,
        );
    }
  }

  /// Extract error message from error response
  String? _extractErrorMessage(dynamic errorData) {
    if (errorData == null) return null;
    
    if (errorData is Map<String, dynamic>) {
      // Try common error message fields
      return errorData['message'] as String? ??
          errorData['error'] as String? ??
          errorData['msg'] as String?;
    }
    
    return null;
  }

  /// Extract validation errors from error response
  Map<String, List<String>>? _extractValidationErrors(dynamic errorData) {
    if (errorData is Map<String, dynamic>) {
      final errors = errorData['errors'] as Map<String, dynamic>?;
      if (errors != null) {
        return errors.map((key, value) {
          if (value is List) {
            return MapEntry(key, value.map((e) => e.toString()).toList());
          }
          return MapEntry(key, [value.toString()]);
        });
      }
    }
    return null;
  }

  /// Handle network errors and convert to appropriate exception
  ApiException handleNetworkError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout') || 
        errorString.contains('timed out')) {
      return const TimeoutException();
    }
    
    if (errorString.contains('cors') ||
        (errorString.contains('redirect') && errorString.contains('preflight')) ||
        errorString.contains('err_failed') ||
        (errorString.contains('blocked') && errorString.contains('policy'))) {
      return UnknownException(
        message: 'Không kết nối được tới máy chủ từ trình duyệt. '
            'Hãy tải lại trang, kiểm tra mạng hoặc thử lại sau.',
        originalError: error,
      );
    }
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return const NetworkException();
    }
    
    return UnknownException(
      message: 'Có lỗi xảy ra. Vui lòng thử lại sau.',
      originalError: error,
    );
  }

  /// GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      var uri = buildUrl(endpoint);
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final response = await http.get(
        uri,
        headers: await buildHeaders(
          additionalHeaders: headers,
          includeAuth: includeAuth,
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw const TimeoutException();
        },
      );

      if (parser != null) {
        return handleResponse(response, parser);
      }
      
      return response as T;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw handleNetworkError(e);
    }
  }

  /// POST request
  Future<T> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.post(
        buildUrl(endpoint),
        headers: await buildHeaders(
          additionalHeaders: headers,
          includeAuth: includeAuth,
        ),
        body: body != null ? json.encode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw const TimeoutException();
        },
      );

      if (parser != null) {
        return handleResponse(response, parser);
      }
      
      return response as T;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw handleNetworkError(e);
    }
  }

  /// PUT request
  Future<T> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.put(
        buildUrl(endpoint),
        headers: await buildHeaders(
          additionalHeaders: headers,
          includeAuth: includeAuth,
        ),
        body: body != null ? json.encode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw const TimeoutException();
        },
      );

      if (parser != null) {
        return handleResponse(response, parser);
      }
      
      return response as T;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw handleNetworkError(e);
    }
  }

  /// DELETE request
  Future<T> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.delete(
        buildUrl(endpoint),
        headers: await buildHeaders(
          additionalHeaders: headers,
          includeAuth: includeAuth,
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw const TimeoutException();
        },
      );

      if (parser != null) {
        return handleResponse(response, parser);
      }
      
      return response as T;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw handleNetworkError(e);
    }
  }
}

