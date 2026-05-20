/// Map pattern tiếng Anh từ backend → tiếng Việt.
/// Để hiển thị lỗi cho người dùng, dùng `UserFacingError` trong `user_facing_error.dart`.
class ErrorMessageParser {
  /// Default error message when parsing fails
  static const String defaultErrorMessage = 'Có lỗi xảy ra. Vui lòng thử lại sau.';

  /// Error message mappings
  static final Map<String, String> _errorMappings = {
    'group not found': 'Không tìm thấy nhóm. Vui lòng thử lại.',
    'group already exists': 'Tên nhóm đã tồn tại. Vui lòng chọn tên khác.',
    'user not found': 'Không tìm thấy người dùng. Vui lòng thử lại.',
    'invitation not found': 'Không tìm thấy lời mời. Vui lòng thử lại.',
    'email.*already': 'Email này đã được mời vào nhóm.',
    'email.*exist': 'Email này đã tồn tại trong hệ thống.',
    'network': 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
    'socketexception': 'Không kết nối được đến máy chủ. Vui lòng kiểm tra mạng và thử lại.',
    'failed host lookup': 'Không tìm thấy máy chủ API. Hãy kiểm tra lại IP/port backend và mạng Wi‑Fi.',
    'connection refused': 'Máy chủ từ chối kết nối. Hãy kiểm tra backend đã chạy và mở cổng 8080.',
    'connection reset by peer': 'Kết nối bị máy chủ đóng. Vui lòng thử lại sau ít phút.',
    'connection': 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
    'timeout': 'Yêu cầu quá thời gian chờ. Vui lòng thử lại.',
    r'oauth2\.0': 'Đăng nhập Google chưa được cấu hình cho bản APK này. Vui lòng dùng Email/Mật khẩu hoặc cập nhật SHA-1 trên Firebase.',
    'not registered to use oauth2': 'Đăng nhập Google chưa được cấu hình cho bản APK này. Vui lòng dùng Email/Mật khẩu hoặc cập nhật SHA-1 trên Firebase.',
    'developer_error': 'Đăng nhập Google chưa được cấu hình đúng. Vui lòng dùng Email/Mật khẩu tạm thời.',
    'permission': 'Bạn không có quyền thực hiện thao tác này.',
    'unauthorized': 'Bạn không có quyền thực hiện thao tác này.',
    'forbidden': 'Bạn không có quyền thực hiện thao tác này.',
    'validation': 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.',
    'server error': 'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.',
    'bad request': 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại.',
    'invalid metric': 'Loại chỉ số này chưa được hỗ trợ. Hãy chọn chỉ số khác hoặc thử lại sau.',
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

