import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
  final User user;
  const HomeAppBar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(
        children: [
          Image.asset(
            AppAssets.appLogo,
            width: 30,
            height: 30,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.health_and_safety_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'HealthMate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textGrey,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primaryContainer,
            child: user.picture == null
                ? const Icon(AppIcons.userAvatar, color: AppColors.primary, size: 20)
                : null,
          ),
        ],
      ),
    );
  }
}