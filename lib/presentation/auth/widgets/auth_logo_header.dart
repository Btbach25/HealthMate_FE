import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthLogoHeader extends StatelessWidget {
  const AuthLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 36, bottom: 20),
      child: Column(
        children: [
          Image.asset(
            'assets/icons/app_logo.png',
            height: 52,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.health_and_safety_outlined,
              size: 52,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'HealthMate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
