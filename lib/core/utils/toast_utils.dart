import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Sắc thái toast — quyết định màu nền và icon.
enum ToastType { success, error, info }

/// Toast (SnackBar nổi, bo góc) dùng chung cho toàn app.
///
/// Dùng khi cần báo nhanh kết quả một thao tác mà không chặn thao tác kế tiếp.
/// Với thông báo cần hiển thị *bên trong* dialog/form (SnackBar bị dialog che),
/// hãy dùng `InlineMessageMixin` thay vì toast.
///
/// ```dart
/// ToastUtils.showCustomToast(context, 'Đã lưu', ToastType.success);
/// ```
class ToastUtils {
  /// Hiển thị toast [message] với sắc thái [type] trên `ScaffoldMessenger`
  /// gần nhất. Gọi sau `await` thì nhớ kiểm tra `context.mounted` trước.
  static void showCustomToast(
    BuildContext context,
    String message,
    ToastType type,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIconForType(type), color: Colors.white),
            const SizedBox(width: 12.0),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _getColorForType(type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.all(16.0),
      ),
    );
  }

  static Color _getColorForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.error:
        return AppColors.error;
      case ToastType.info:
        return Colors.blue;
    }
  }

  static IconData _getIconForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.highlight_off;
      case ToastType.info:
        return Icons.info_outline;
    }
  }
}
