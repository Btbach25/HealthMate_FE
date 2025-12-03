import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:flutter/material.dart';

class FamilyAppBar extends StatelessWidget {
  const FamilyAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 4),
              const Text(
                'HealthMate',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          CircleAvatar(
            backgroundColor: AppColors.inputBackground,
            child: const Icon(
              AppIcons.userAvatar,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}



