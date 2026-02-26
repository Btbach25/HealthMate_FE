import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class WelcomeMessage extends StatelessWidget {
  final String name;
  const WelcomeMessage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textBlack,
        ),
        children: [
          const TextSpan(text: 'Xin chào, '),
          TextSpan(
            text: name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: '! 👋'),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}