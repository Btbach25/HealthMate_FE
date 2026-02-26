/// Helper class for form validation
/// Provides reusable validation logic
class FormValidationHelper {
  /// Validates email format
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

  /// Validates required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập ${fieldName ?? 'thông tin này'}';
    }
    return null;
  }

  /// Validates minimum length
  static String? validateMinLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập ${fieldName ?? 'thông tin này'}';
    }
    if (value.trim().length < minLength) {
      return '${fieldName ?? 'Thông tin'} phải có ít nhất $minLength ký tự';
    }
    return null;
  }

  /// Validates maximum length
  static String? validateMaxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.trim().length > maxLength) {
      return '${fieldName ?? 'Thông tin'} không được vượt quá $maxLength ký tự';
    }
    return null;
  }

  /// Validates date is not in the future
  static String? validateDateNotFuture(DateTime? date, {String? fieldName}) {
    if (date != null && date.isAfter(DateTime.now())) {
      return '${fieldName ?? 'Ngày'} không thể lớn hơn ngày hiện tại';
    }
    return null;
  }

  /// Validates phone number (Vietnamese format)
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

