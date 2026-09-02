/// Bảng tra: mẫu chuỗi lỗi tiếng Anh từ backend → câu tiếng Việt cho người dùng.
///
/// **Đừng gọi trực tiếp từ UI.** Lớp ngoài cùng là `UserFacingError` trong
/// `user_facing_error.dart` — nó bóc `ApiException`, xử các trường hợp riêng
/// (CORS, UUID hỏng, lỗi mời thành viên) rồi mới rơi về lớp này.
/// `ErrorMessageParser` chỉ là bước tra bảng cuối cùng.
///
/// Thêm mẫu mới thì thêm vào [_errorMappings], nhớ đọc kỹ ghi chú về thứ tự
/// ở đó.
class ErrorMessageParser {
  /// Câu mặc định khi không tra được gì hoặc chuỗi lỗi không dùng để hiển thị.
  static const String defaultErrorMessage =
      'Có lỗi xảy ra. Vui lòng thử lại sau.';

  /// Mẫu (regex, không phân biệt hoa thường) → câu tiếng Việt.
  ///
  /// **THỨ TỰ CÓ Ý NGHĨA**: [parse] duyệt tuần tự và lấy mẫu khớp ĐẦU TIÊN.
  /// Vì vậy mẫu cụ thể phải đứng trước mẫu tổng quát — `'connection refused'`
  /// nằm trên `'connection'`, nếu đảo lại thì thông báo chi tiết về cổng 8080
  /// sẽ không bao giờ hiện ra.
  static final Map<String, String> _errorMappings = {
    'group not found': 'Không tìm thấy nhóm. Vui lòng thử lại.',
    'group already exists': 'Tên nhóm đã tồn tại. Vui lòng chọn tên khác.',
    'user not found': 'Không tìm thấy người dùng. Vui lòng thử lại.',
    'invitation not found': 'Không tìm thấy lời mời. Vui lòng thử lại.',
    'email.*already': 'Email này đã được mời vào nhóm.',
    'email.*exist': 'Email này đã tồn tại trong hệ thống.',
    'network': 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
    'socketexception':
        'Không kết nối được đến máy chủ. Vui lòng kiểm tra mạng và thử lại.',
    'failed host lookup':
        'Không tìm thấy máy chủ API. Hãy kiểm tra lại IP/port backend và mạng Wi‑Fi.',
    'connection refused':
        'Máy chủ từ chối kết nối. Hãy kiểm tra backend đã chạy và mở cổng 8080.',
    'connection reset by peer':
        'Kết nối bị máy chủ đóng. Vui lòng thử lại sau ít phút.',
    'connection': 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
    'timeout': 'Yêu cầu quá thời gian chờ. Vui lòng thử lại.',
    r'oauth2\.0':
        'Đăng nhập Google chưa được cấu hình cho bản APK này. Vui lòng dùng Email/Mật khẩu hoặc cập nhật SHA-1 trên Firebase.',
    'not registered to use oauth2':
        'Đăng nhập Google chưa được cấu hình cho bản APK này. Vui lòng dùng Email/Mật khẩu hoặc cập nhật SHA-1 trên Firebase.',
    'developer_error':
        'Đăng nhập Google chưa được cấu hình đúng. Vui lòng dùng Email/Mật khẩu tạm thời.',
    'permission': 'Bạn không có quyền thực hiện thao tác này.',
    'unauthorized': 'Bạn không có quyền thực hiện thao tác này.',
    'forbidden': 'Bạn không có quyền thực hiện thao tác này.',
    'validation': 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.',
    'server error': 'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.',
    'bad request': 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại.',
    'invalid metric':
        'Loại chỉ số này chưa được hỗ trợ. Hãy chọn chỉ số khác hoặc thử lại sau.',
  };

  /// Đổi chuỗi lỗi thô thành câu tiếng Việt hiển thị được.
  ///
  /// Không tra được mẫu nào thì trả lại chính chuỗi gốc — trừ khi nó dài quá
  /// 100 ký tự hoặc còn chứa "Exception", vì đó gần như chắc chắn là stack
  /// trace / thông điệp nội bộ, không nên đưa cho người dùng xem.
  static String parse(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return defaultErrorMessage;
    }

    // Bỏ tiền tố "Exception: " mà Dart tự thêm khi ném Exception.
    final cleanMessage = errorMessage
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();

    if (cleanMessage.isEmpty) {
      return defaultErrorMessage;
    }

    final lowerError = cleanMessage.toLowerCase();

    // Khớp regex, lấy mẫu đầu tiên trúng (xem ghi chú thứ tự ở _errorMappings).
    for (final entry in _errorMappings.entries) {
      final pattern = RegExp(entry.key, caseSensitive: false);
      if (pattern.hasMatch(lowerError)) {
        return entry.value;
      }
    }

    // Không mẫu nào khớp: chuỗi quá dài hoặc còn dấu vết Exception thì bỏ,
    // ngược lại trả nguyên văn (backend đôi khi đã gửi sẵn tiếng Việt).
    if (cleanMessage.length > 100 || cleanMessage.contains('Exception')) {
      return defaultErrorMessage;
    }

    return cleanMessage;
  }

  /// Thêm một mẫu lỗi lúc chạy.
  ///
  /// Hiện chưa nơi nào dùng. Lưu ý mẫu thêm bằng hàm này luôn nằm CUỐI bảng
  /// nên không thể chèn trước một mẫu tổng quát đã có — muốn ưu tiên cao hơn
  /// thì phải khai báo thẳng vào [_errorMappings].
  static void addMapping(String pattern, String message) {
    _errorMappings[pattern] = message;
  }
}
