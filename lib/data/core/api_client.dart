import 'dart:convert';

import 'package:fe/data/exceptions/api_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP client dùng chung cho tầng data: ghép base URL, gắn header
/// `Authorization`, đặt timeout 30s, và quy đổi lỗi HTTP/mạng thành
/// [ApiException] có message tiếng Việt hiển thị được cho người dùng.
///
/// Lớp abstract: chỉ định nghĩa cách gọi, không biết token lấy từ đâu.
/// Lớp con phải cài [baseUrl] và [getAuthToken] — xem `ApiClientImpl`.
/// Implementation dùng thật được đăng ký ở
/// `lib/core/di/app_dependencies.dart` (composition root).
abstract class ApiClient {
  /// Gốc URL của API (không có dấu `/` ở cuối).
  String get baseUrl;

  /// Header mặc định cho mọi request; lớp gọi có thể ghi đè qua
  /// `additionalHeaders`.
  Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Access token hiện tại, hoặc null nếu chưa đăng nhập. Lớp con tự quyết
  /// định nguồn token (storage, memory...).
  Future<String?> getAuthToken();

  /// Ghép [endpoint] vào [baseUrl]. Nếu [endpoint] đã là URL tuyệt đối
  /// (bắt đầu bằng `http`) thì dùng nguyên vẹn — cho phép gọi service ngoài.
  Uri buildUrl(String endpoint) {
    final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    return Uri.parse(url);
  }

  /// Dựng header cho một request. Chỉ gắn `Authorization` khi [includeAuth]
  /// true VÀ [getAuthToken] trả về token — endpoint public (login, register)
  /// phải truyền `includeAuth: false`.
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

  /// Parse response 2xx bằng [parser]; ngoài 2xx thì ném [ApiException]
  /// tương ứng với status code.
  ///
  /// Body rỗng được truyền vào [parser] dưới dạng `null` (BE hay trả 204 /
  /// body rỗng cho DELETE), nên [parser] phải chịu được `null`.
  T handleResponse<T>(http.Response response, T Function(dynamic) parser) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = response.body.isEmpty ? null : json.decode(response.body);
        return parser(data);
      } catch (e) {
        throw UnknownException(
          message: 'Không đọc được dữ liệu trả về. Vui lòng thử lại sau.',
          originalError: e,
        );
      }
    } else {
      throw _handleErrorResponse(response);
    }
  }

  /// Quy đổi response ngoài 2xx thành [ApiException] cụ thể theo status
  /// code, kèm message lấy từ body nếu BE có trả.
  ApiException _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic errorData;

    try {
      if (response.body.isNotEmpty) {
        errorData = json.decode(response.body);
      }
    } catch (_) {
      // Body không phải JSON hợp lệ (BE có thể trả HTML lỗi từ gateway)
      // -> bỏ qua, dùng message mặc định theo status code.
    }

    // Chỉ log method/URL/status. KHÔNG log body: `debugPrint` vẫn chạy ở bản
    // release nên mọi thứ ở đây sẽ hiện trong Console của trình duyệt, mà body
    // lỗi có thể chứa email, tên thành viên nhóm hay chỉ số sức khoẻ.
    debugPrint(
      '[API] ${response.request?.method} ${response.request?.url} → $statusCode '
      '(${response.body.length}B)',
    );

    final errorMessage =
        _extractErrorMessage(errorData) ?? 'Có lỗi xảy ra. Vui lòng thử lại.';

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

  /// Lấy message lỗi từ body JSON, hoặc null nếu không tìm thấy.
  String? _extractErrorMessage(dynamic errorData) {
    if (errorData == null) return null;

    if (errorData is Map<String, dynamic>) {
      // BE không thống nhất tên field chứa message lỗi -> thử lần lượt.
      return errorData['message'] as String? ??
          errorData['error'] as String? ??
          errorData['msg'] as String?;
    }

    return null;
  }

  /// Lấy map lỗi theo từng field cho response 422 (`errors`).
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

  /// Quy đổi lỗi tầng mạng thành [ApiException].
  ///
  /// Nhận diện bằng cách dò chuỗi trong thông báo lỗi vì `package:http`
  /// ném kiểu khác nhau trên từng nền tảng (web vs mobile) — cách này thô
  /// nhưng là cách duy nhất phân biệt được CORS/timeout/mất mạng.
  ApiException handleNetworkError(dynamic error) {
    if (error is ApiException) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return const TimeoutException();
    }

    if (errorString.contains('cors') ||
        (errorString.contains('redirect') &&
            errorString.contains('preflight')) ||
        errorString.contains('err_failed') ||
        (errorString.contains('blocked') && errorString.contains('policy'))) {
      return UnknownException(
        message:
            'Ứng dụng không kết nối được từ trình duyệt. '
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

  /// GET [endpoint], timeout 30s.
  ///
  /// Nếu [parser] null thì trả về thẳng `http.Response` (caller phải khai
  /// báo `T` là `http.Response`, nếu không sẽ lỗi cast lúc chạy).
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

      final response = await http
          .get(
            uri,
            headers: await buildHeaders(
              additionalHeaders: headers,
              includeAuth: includeAuth,
            ),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw const TimeoutException();
            },
          );

      if (parser != null) {
        return await handleResponse(response, parser);
      }

      return response as T;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw handleNetworkError(e);
    }
  }

  /// POST [endpoint] với [body] được encode JSON; timeout 30s.
  /// Ràng buộc [parser] giống [get].
  Future<T> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            buildUrl(endpoint),
            headers: await buildHeaders(
              additionalHeaders: headers,
              includeAuth: includeAuth,
            ),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw const TimeoutException();
            },
          );

      if (parser != null) {
        return await handleResponse(response, parser);
      }

      return response as T;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw handleNetworkError(e);
    }
  }

  /// PUT [endpoint] với [body] được encode JSON; timeout 30s.
  /// Ràng buộc [parser] giống [get].
  Future<T> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .put(
            buildUrl(endpoint),
            headers: await buildHeaders(
              additionalHeaders: headers,
              includeAuth: includeAuth,
            ),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw const TimeoutException();
            },
          );

      if (parser != null) {
        return await handleResponse(response, parser);
      }

      return response as T;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw handleNetworkError(e);
    }
  }

  /// DELETE [endpoint], timeout 30s. Ràng buộc [parser] giống [get].
  Future<T> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .delete(
            buildUrl(endpoint),
            headers: await buildHeaders(
              additionalHeaders: headers,
              includeAuth: includeAuth,
            ),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw const TimeoutException();
            },
          );

      if (parser != null) {
        return await handleResponse(response, parser);
      }

      return response as T;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw handleNetworkError(e);
    }
  }
}
