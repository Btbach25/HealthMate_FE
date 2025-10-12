import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ToastType { success, error, info }

class ToastUtils {
  static void showCustomToast(BuildContext context, String message, ToastType type) {
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