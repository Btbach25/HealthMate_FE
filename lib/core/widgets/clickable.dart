import 'package:flutter/material.dart';

/// Vùng bấm có con trỏ bàn tay trên web/desktop — thay thế cho
/// `GestureDetector(onTap: ...)`.
///
/// `GestureDetector` không đổi con trỏ chuột, nên trên web mọi thẻ/ô bấm được
/// vẫn hiện con trỏ mũi tên và người dùng không đoán ra là bấm được. Dùng
/// widget này cho **thẻ và ô tự vẽ nền** (card, tile, chip có `Container` +
/// `BoxDecoration` riêng).
///
/// ```dart
/// Clickable(
///   onTap: () => context.push('/family/group/$id'),
///   child: Container(decoration: ..., child: ...),
/// )
/// ```
///
/// Khi [onTap] là `null`, con trỏ giữ nguyên mặc định — nhờ vậy ô đang bị vô
/// hiệu hoá không "giả vờ" bấm được.
///
/// Cần **hiệu ứng gợn sóng (ripple) và vệt hover** thì dùng `InkWell` bọc
/// trong `Material` thay vì widget này — xem `_NavItem` trong `app_shell.dart`.
class Clickable extends StatelessWidget {
  const Clickable({
    super.key,
    required this.onTap,
    required this.child,
    this.behavior = HitTestBehavior.opaque,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// Mặc định `opaque` để cả vùng con — kể cả khoảng trống trong suốt — đều
  /// nhận được cú chạm.
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: behavior,
        child: child,
      ),
    );
  }
}
