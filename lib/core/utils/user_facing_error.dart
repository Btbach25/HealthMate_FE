import 'package:fe/core/utils/error_message_parser.dart';
import 'package:fe/data/exceptions/api_exception.dart';

/// Chuẩn hóa lỗi hiển thị cho người dùng — **một nơi dùng chung** (bloc, snackbar, …).
/// Không lộ thuật ngữ dev (CORS, token, engine, …).
abstract final class UserFacingError {
  UserFacingError._();

  /// Mọi lỗi chung từ repository / API / `Exception`.
  static String message(Object? error) {
    if (error == null) return ErrorMessageParser.defaultErrorMessage;
    final text = _rawText(error);
    return _applyCommonHints(text);
  }

  /// Lỗi khi mời thành viên nhóm (ưu tiên nội dung riêng, rồi [message]).
  static String inviteMember(Object? error) {
    if (error == null) return ErrorMessageParser.defaultErrorMessage;
    final text = _rawText(error);
    final lower = text.toLowerCase();
    if (lower.contains('invalid request')) {
      return 'Không gửi được lời mời. Kiểm tra email đúng định dạng và '
          'người nhận đã có tài khoản trong ứng dụng.';
    }
    if (lower.contains('invitation is still pending') ||
        lower.contains('still pending')) {
      return 'Lời mời đang chờ người này phản hồi. Không thể gửi thêm.';
    }
    if (lower.contains('already a member')) {
      return 'Người này đã là thành viên của nhóm.';
    }
    return _applyCommonHints(text);
  }

  static String _rawText(Object error) {
    if (error is ApiException) return error.message;
    var s = error.toString();
    if (s.startsWith('Exception: ')) {
      s = s.substring(11).trim();
    }
    return s;
  }

  static String _applyCommonHints(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('cors') ||
        (lower.contains('redirect') && lower.contains('preflight')) ||
        lower.contains('err_failed') ||
        (lower.contains('blocked') && lower.contains('policy'))) {
      return 'Không tải được dữ liệu. Nếu bạn đang dùng trình duyệt, '
          'hãy thử tải lại trang hoặc đăng nhập lại. '
          'Nếu vẫn lỗi, vui lòng thử sau hoặc dùng ứng dụng trên điện thoại.';
    }
    if (lower.contains('invalid uuid format')) {
      return 'Phiên đăng nhập không còn hợp lệ. '
          'Hãy đăng xuất và đăng nhập lại, rồi thử một lần nữa.';
    }
    return ErrorMessageParser.parse(text);
  }
}
