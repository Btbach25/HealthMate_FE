import 'package:fe/presentation/settings/view/settings_view.dart';
import 'package:flutter/material.dart';

/// Điểm vào của nhánh Cài đặt trong shell — được `app_router.dart` dựng cho
/// route `/settings`.
///
/// Cố ý mỏng: chỉ trả về [SettingsView]. Lớp bọc này là chỗ để sau này gắn
/// những thứ thuộc về ROUTE chứ không thuộc về màn hình (BlocProvider riêng
/// cho tab, đọc query param, guard quyền…) mà không phải đụng vào
/// [SettingsView]. Nếu tới lúc dọn dẹp mà nó vẫn rỗng thế này thì cứ cho router
/// trỏ thẳng vào [SettingsView] — nhánh Thuốc đang làm đúng như vậy.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsView();
  }
}
