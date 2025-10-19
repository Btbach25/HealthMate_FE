import 'package:fe/core/constants/app_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_size.dart';

class FeaturedMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const FeaturedMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSize.p16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSize.r12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08), // Bóng mờ rất nhẹ
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        // Nội dung bên trong card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: AppSize.p12),
            Text(label, style: AppStyles.bodyLg),
            const SizedBox(height: AppSize.p4),
            Text(value, style: AppStyles.h1.copyWith(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}