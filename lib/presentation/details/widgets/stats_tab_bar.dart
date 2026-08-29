import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Thanh tab kiểu "pill" (viên thuốc) của màn Chỉ số: 3 tab cố định
/// Gần đây / Tổng quan / Biểu đồ.
///
/// Tham số bắt buộc:
/// - [controller]: `TabController` do màn cha sở hữu (phải có `length: 3` khớp
///   với số tab bên dưới).
///
/// Widget implement `PreferredSizeWidget` để đặt được vào `SliverAppBar.bottom`
/// — đó là lý do phải khai báo [preferredSize] khớp với chiều cao Container.
/// Sửa chiều cao thì phải sửa cả hai chỗ, nếu không tab sẽ bị cắt hoặc dư chỗ.
///
/// Khi nào nên tái sử dụng: chỉ khi cần đúng 3 tab này. Cần bộ tab khác thì
/// nhân bản và đổi danh sách `tabs` — phần trang trí (nền, indicator, đổ bóng)
/// là thứ đáng chép lại.
class StatsTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  const StatsTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TabBar(
        controller: controller,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textGrey,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        tabs: const [
          Tab(text: 'Gần đây'),
          Tab(text: 'Tổng quan'),
          Tab(text: 'Biểu đồ'),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(44);
}
