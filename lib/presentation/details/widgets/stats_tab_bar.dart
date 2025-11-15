import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

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
              color: Colors.black.withOpacity(0.05),
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