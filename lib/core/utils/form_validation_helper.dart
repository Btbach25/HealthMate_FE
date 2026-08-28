/// Các validator dùng cho `TextFormField.validator` trong toàn app.
///
/// Mọi hàm ở đây theo đúng hợp đồng của Flutter Form: trả `null` khi hợp lệ,
/// trả chuỗi lỗi **tiếng Việt** khi không hợp lệ — nối thẳng vào `validator:`
/// được ngay.
///
/// Tham số `fieldName` đi vào giữa câu lỗi nên hãy truyền dạng thường,
/// không viết hoa: `'họ tên'` → "Vui lòng nhập họ tên".
///
/// ```dart
/// ProfileTextField(
///   controller: _emailCtrl,
///   label: 'Email',
///   validator: FormValidationHelper.validateEmail,
/// )
/// ```
///
/// Cần ghép nhiều luật thì gọi lần lượt và trả lỗi đầu tiên:
///
/// ```dart
/// validator: (v) =>
///     FormValidationHelper.validateRequired(v, fieldName: 'tên nhóm') ??
///     FormValidationHelper.validateMaxLength(v, 50, fieldName: 'Tên nhóm'),
/// ```
class FormValidationHelper {
  /// Bắt buộc nhập + đúng dạng `a@b.c`.
  ///
  /// Cố ý chỉ kiểm tra thô (có `@`, có dấu chấm ở phần miền): email hợp lệ
  /// thật hay không do backend xác nhận, regex chặt hơn chỉ làm người dùng
  /// bị chặn oan với các miền lạ.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    final regex = RegExp(emailPattern);
    if (!regex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  /// Bắt buộc nhập. Chuỗi chỉ toàn khoảng trắng cũng bị coi là bỏ trống.
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập ${fieldName ?? 'thông tin này'}';
    }
    return null;
  }

  /// Bắt buộc nhập + tối thiểu [minLength] ký tự (đếm sau khi trim).
  static String? validateMinLength(
    String? value,
    int minLength, {
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập ${fieldName ?? 'thông tin này'}';
    }
    if (value.trim().length < minLength) {
      return '${fieldName ?? 'Thông tin'} phải có ít nhất $minLength ký tự';
    }
    return null;
  }

  /// Tối đa [maxLength] ký tự.
  ///
  /// KHÔNG bắt buộc nhập — bỏ trống vẫn hợp lệ. Ghép với [validateRequired]
  /// nếu trường đó bắt buộc.
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String? fieldName,
  }) {
    if (value != null && value.trim().length > maxLength) {
      return '${fieldName ?? 'Thông tin'} không được vượt quá $maxLength ký tự';
    }
    return null;
  }

  /// Ngày không được ở tương lai — dùng cho ngày sinh, ngày đo chỉ số.
  ///
  /// Nhận `DateTime` (không phải `String`) nên gọi thủ công từ ngày đang giữ
  /// trong state, chứ không gắn vào `validator:` của ô nhập được.
  static String? validateDateNotFuture(DateTime? date, {String? fieldName}) {
    if (date != null && date.isAfter(DateTime.now())) {
      return '${fieldName ?? 'Ngày'} không thể lớn hơn ngày hiện tại';
    }
    return null;
  }

  /// Số điện thoại Việt Nam: bắt đầu bằng `0` hoặc `+84`, theo sau 9-10 chữ số.
  ///
  /// Khoảng trắng và gạch nối được bỏ trước khi khớp, nên người dùng gõ
  /// "090 123 4567" vẫn qua.
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final phonePattern = r'^(0|\+84)[0-9]{9,10}$';
    final regex = RegExp(phonePattern);
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!regex.hasMatch(cleaned)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }
}
