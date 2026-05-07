/// Base exception class for API errors
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Network related exceptions
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
    super.statusCode,
    super.originalError,
  });
}

/// Timeout exceptions
class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'Yêu cầu quá thời gian chờ. Vui lòng thử lại.',
    super.statusCode,
    super.originalError,
  });
}

/// Server errors (5xx)
class ServerException extends ApiException {
  const ServerException({
    super.message = 'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.',
    super.statusCode,
    super.originalError,
  });
}

/// Client errors (4xx)
class ClientException extends ApiException {
  const ClientException({
    required super.message,
    super.statusCode,
    super.originalError,
  });
}

/// Unauthorized errors (401)
class UnauthorizedException extends ClientException {
  const UnauthorizedException({
    super.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    super.statusCode = 401,
    super.originalError,
  });
}

/// Forbidden errors (403)
class ForbiddenException extends ClientException {
  const ForbiddenException({
    super.message = 'Bạn không có quyền thực hiện thao tác này.',
    super.statusCode = 403,
    super.originalError,
  });
}

/// Not found errors (404)
class NotFoundException extends ClientException {
  const NotFoundException({
    super.message = 'Không tìm thấy dữ liệu. Vui lòng thử lại.',
    super.statusCode = 404,
    super.originalError,
  });
}

/// Validation errors (422)
class ValidationException extends ClientException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    super.message = 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.',
    super.statusCode = 422,
    super.originalError,
    this.errors,
  });
}

/// Unknown/Generic errors
class UnknownException extends ApiException {
  const UnknownException({
    super.message = 'Có lỗi xảy ra. Vui lòng thử lại sau.',
    super.statusCode,
    super.originalError,
  });
}

