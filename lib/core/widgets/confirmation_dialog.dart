import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Hộp thoại xác nhận dùng chung (đang dùng ở Gia đình và Cài đặt).
///
/// Thường không dựng trực tiếp mà gọi qua hai hàm tĩnh:
/// - [ConfirmationDialog.showConfirmation] — hành động thường.
/// - [ConfirmationDialog.showErrorConfirmation] — hành động phá huỷ
///   (xoá nhóm, rời nhóm…), nút xác nhận tô màu đỏ.
///
/// ```dart
/// ConfirmationDialog.showErrorConfirmation(
///   context: context,
///   title: 'Xoá nhóm?',
///   message: 'Thao tác này không thể hoàn tác.',
///   onConfirm: () => bloc.add(DeleteGroup(id)),
/// );
/// ```
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Xác nhận',
    this.cancelText = 'Hủy',
    this.confirmColor,
    required this.onConfirm,
    this.onCancel,
  });

  /// Luôn đóng dialog TRƯỚC rồi mới chạy callback trong
  /// `addPostFrameCallback`: callback thường điều hướng hoặc bắn event bloc,
  /// nếu chạy khi dialog còn trên stack thì `context` bị huỷ giữa chừng.
  /// `rootNavigator: true` để pop đúng dialog chứ không pop route bên trong
  /// shell (bottom nav).
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: AppTextStyles.h4.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            if (onCancel != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onCancel!();
              });
            }
          },
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onConfirm();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Mở hộp thoại xác nhận cho hành động phá huỷ (nút xác nhận màu lỗi).
  ///
  /// [onConfirm] chạy SAU khi dialog đã đóng (xem ghi chú ở [build]), nên
  /// đừng dùng lại `context` của dialog bên trong callback.
  static Future<void> showErrorConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: AppColors.error,
        onConfirm: onConfirm,
      ),
    );
  }

  /// Mở hộp thoại xác nhận thường (nút xác nhận màu primary).
  ///
  /// [onCancel] chỉ chạy khi người dùng bấm nút Huỷ — bấm ra ngoài hoặc nút
  /// back của hệ thống sẽ đóng dialog mà KHÔNG gọi callback nào.
  static Future<void> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
    Color? confirmColor,
    VoidCallback? onCancel,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }
}

