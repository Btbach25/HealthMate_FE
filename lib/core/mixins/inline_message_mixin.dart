import 'dart:async';
import 'package:flutter/material.dart';

/// Thông báo dạng dải chữ hiển thị NGAY TRONG dialog/form.
///
/// Dùng khi `SnackBar` không hợp: nó nổi ở đáy `Scaffold` nên bị dialog che
/// và biến mất cùng lúc dialog đóng. Mixin này giữ thông báo trong chính
/// khung nội dung, tự ẩn sau [showInlineMessage] duration (mặc định 5 giây)
/// và tự huỷ `Timer` trong `dispose`.
///
/// Cách dùng: `with InlineMessageMixin` trên `State`, gọi
/// [showInlineMessage] khi có lỗi, và chèn [buildInlineMessage] vào cây
/// widget (nó trả `null` khi không có thông báo):
///
/// ```dart
/// class _MyDialogState extends State<MyDialog>
///     with InlineMessageMixin<MyDialog> {
///   @override
///   Widget build(BuildContext context) {
///     final banner = buildInlineMessage();
///     return Column(children: [
///       if (banner != null) ...[banner, const SizedBox(height: 12)],
///       // …
///     ]);
///   }
/// }
/// ```
mixin InlineMessageMixin<T extends StatefulWidget> on State<T> {
  String? _inlineMessage;
  Color? _inlineMessageColor;
  Timer? _messageTimer;

  String? get inlineMessage => _inlineMessage;
  Color? get inlineMessageColor => _inlineMessageColor;

  /// Hiện [message], thay thế thông báo đang có (timer cũ bị huỷ).
  ///
  /// [backgroundColor] nên là `AppColors.error` cho lỗi, `AppColors.primary`
  /// cho thành công; bỏ trống thì dùng nền đen mờ trung tính.
  void showInlineMessage(
    String message, {
    Color? backgroundColor,
    Duration? duration,
  }) {
    final messageDuration = duration ?? const Duration(seconds: 5);
    _messageTimer?.cancel();
    setState(() {
      _inlineMessage = message;
      _inlineMessageColor = backgroundColor ?? Colors.black.withValues(alpha: 0.85);
    });
    _messageTimer = Timer(messageDuration, () {
      if (mounted) {
        setState(() {
          _inlineMessage = null;
        });
      }
    });
  }

  /// Ẩn thông báo ngay, không đợi hết thời gian tự ẩn.
  ///
  /// Hữu ích khi người dùng bắt đầu sửa lại form sau một lỗi.
  void clearInlineMessage() {
    _messageTimer?.cancel();
    if (mounted) {
      setState(() {
        _inlineMessage = null;
      });
    }
  }

  /// Dựng dải thông báo, hoặc `null` nếu hiện không có thông báo nào.
  ///
  /// Trả `null` (chứ không phải `SizedBox.shrink()`) để phía gọi tự quyết
  /// khoảng cách bao quanh khi thông báo xuất hiện.
  Widget? buildInlineMessage() {
    if (_inlineMessage == null) return null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _inlineMessageColor ?? Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _inlineMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }
}

