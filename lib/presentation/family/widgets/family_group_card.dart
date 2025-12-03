import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/data/enums/group_member_role.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FamilyGroupCard extends StatelessWidget {
  final FamilyGroup group;

  const FamilyGroupCard({super.key, required this.group});

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa có hoạt động';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String _getMetricLabel(MetricType metric) {
    switch (metric) {
      case MetricType.heartRate:
        return 'Nhịp tim';
      case MetricType.stepsCount:
        return 'Bước chân';
      case MetricType.caloriesBurnt:
        return 'Calo';
      case MetricType.bloodPressure:
        return 'Huyết áp';
      case MetricType.weight:
        return 'Cân nặng';
      case MetricType.sleep:
        return 'Giấc ngủ';
      case MetricType.temperature:
        return 'Nhiệt độ';
    }
  }

  IconData _getMetricIcon(MetricType metric) {
    switch (metric) {
      case MetricType.heartRate:
        return AppIcons.heart;
      case MetricType.stepsCount:
        return AppIcons.steps;
      case MetricType.caloriesBurnt:
        return Icons.local_fire_department_outlined;
      case MetricType.bloodPressure:
        return AppIcons.bloodPressure;
      case MetricType.weight:
        return AppIcons.weight;
      case MetricType.sleep:
        return AppIcons.sleep;
      case MetricType.temperature:
        return AppIcons.temperature;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = group.userRole == GroupMemberRole.admin;
    final remainingMetrics = group.sharedMetrics.length > 3
        ? group.sharedMetrics.length - 3
        : 0;

    return GestureDetector(
      onTap: () {
        // Navigate to group details
        context.push('/family/group/${group.id}');
      },
      child: Container(
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
                padding: const EdgeInsets.all(AppSize.p12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSize.r12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people_outline,
                  color: Colors.white,
                  size: AppSize.icon24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppColors.textGrey.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.memberCount} thành viên',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textGrey.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? AppColors.primary
                                : AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOwner ? 'Chủ nhóm' : 'Thành viên',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOwner
                                  ? Colors.white
                                  : AppColors.textGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textGrey.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ],
          ),
          if (group.sharedMetrics.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...group.sharedMetrics.take(3).map((metric) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                _getMetricIcon(metric),
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getMetricLabel(metric),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textBlack,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (remainingMetrics > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '+$remainingMetrics khác',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textGrey.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hoạt động: ${_formatTimeAgo(group.lastActivity)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (group.pendingInvitations > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 14,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${group.pendingInvitations} lời mời',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

