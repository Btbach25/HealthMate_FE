import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class FamilySummaryCards extends StatelessWidget {
  final int groupsJoined;
  final int pendingInvitations;

  const FamilySummaryCards({
    super.key,
    required this.groupsJoined,
    required this.pendingInvitations,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            value: groupsJoined.toString(),
            label: 'Nhóm tham gia',
            icon: Icons.people_outline_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSize.spacing16),
        Expanded(
          child: _SummaryCard(
            value: pendingInvitations.toString(),
            label: 'Lời mời chờ',
            icon: Icons.mark_email_unread_outlined,
            color: const Color(0xFFE65100),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSize.p20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSize.r16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSize.p8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSize.r10),
                ),
                child: Icon(icon, color: color, size: AppSize.icon20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSize.spacing12),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSize.fontSize32,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSize.spacing8),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}


