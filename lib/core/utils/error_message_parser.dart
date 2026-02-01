/// Utility class to parse and translate error messages
/// Provides consistent error message handling across the app
class ErrorMessageParser {
  /// Default error message when parsing fails
  static const String defaultErrorMessage = 'Có lỗi xảy ra. Vui lòng thử lại sau.';

  /// Error message mappings
  static final Map<String, String> _errorMappings = {
    'group not found': 'Không tìm thấy nhóm. Vui lòng thử lại.',
    'user not found': 'Không tìm thấy người dùng. Vui lòng thử lại.',
    'invitation not found': 'Không tìm thấy lời mời. Vui lòng thử lại.',
    'email.*already': 'Email này đã được mời vào nhóm.',
    'email.*exist': 'Email này đã tồn tại trong hệ thống.',
    'network': 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
    'connection': 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
    'timeout': 'Yêu cầu quá thời gian chờ. Vui lòng thử lại.',
    'permission': 'Bạn không có quyền thực hiện thao tác này.',
    'unauthorized': 'Bạn không có quyền thực hiện thao tác này.',
    'forbidden': 'Bạn không có quyền thực hiện thao tác này.',
    'validation': 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.',
    'server error': 'Lỗi máy chủ. Vui lòng thử lại sau.',
    'bad request': 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại.',
  };

  /// Parses error message and returns user-friendly Vietnamese message
  static String parse(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return defaultErrorMessage;
    }

    // Remove "Exception:" prefix if present
    final cleanMessage = errorMessage
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();

    if (cleanMessage.isEmpty) {
      return defaultErrorMessage;
    }

    final lowerError = cleanMessage.toLowerCase();

    // Check for exact matches first
    for (final entry in _errorMappings.entries) {
      final pattern = RegExp(entry.key, caseSensitive: false);
      if (pattern.hasMatch(lowerError)) {
        return entry.value;
      }
    }

    // If no pattern matches, return the original message if it's reasonable
    // Otherwise return default message
    if (cleanMessage.length > 100 || cleanMessage.contains('Exception')) {
      return defaultErrorMessage;
    }

    return cleanMessage;
  }

  /// Adds a custom error mapping
  static void addMapping(String pattern, String message) {
    _errorMappings[pattern] = message;
  }
}

