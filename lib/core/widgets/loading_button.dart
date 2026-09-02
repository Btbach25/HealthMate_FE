import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Nút hành động có sẵn trạng thái đang xử lý.
///
/// Dùng cho mọi nút gọi API (Lưu, Gửi lời mời, Đăng nhập…): khi [isLoading]
/// bật, nút tự vô hiệu hoá và đổi nhãn thành vòng quay, nhờ vậy không cần
/// tự chặn double-tap ở phía gọi.
///
/// Về bề rộng: mặc định nút giãn hết cha nếu cha có bề rộng xác định; trong
/// cha bề rộng vô hạn (`Row`, `ListView` ngang) nút tự co theo nội dung.
/// Chỉ truyền [width] khi cần ép một con số cụ thể.
///
/// ```dart
/// LoadingButton(
///   text: 'Lưu',
///   icon: Icons.check,
///   isLoading: state.isSubmitting,
///   onPressed: _submit,
/// )
/// ```
class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.padding,
    this.borderRadius,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        disabledBackgroundColor:
            disabledBackgroundColor ??
            (backgroundColor ?? AppColors.primary).withValues(alpha: 0.6),
        padding: padding ?? const EdgeInsets.symmetric(vertical: AppSize.p16),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : icon != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(text),
              ],
            )
          : Text(text),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = width;
        if (resolvedWidth != null) {
          return SizedBox(width: resolvedWidth, child: button);
        }
        if (constraints.hasBoundedWidth) {
          return SizedBox(width: double.infinity, child: button);
        }
        // In unbounded-width parents (e.g. inside Row), let the button
        // size itself naturally to avoid infinite-width constraints.
        return button;
      },
    );
  }
}
