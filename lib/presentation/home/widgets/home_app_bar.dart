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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'HealthMate',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          CircleAvatar(
            backgroundColor: AppColors.inputBackground,
            child: user.picture == null
                ? const Icon(AppIcons.userAvatar, color: AppColors.textGrey)
                : null,
          ),
        ],
      ),
    );
  }
}