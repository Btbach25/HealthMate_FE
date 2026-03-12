import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/string_helper.dart';
import 'package:fe/data/enums/metric_type_extension.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FamilyGroupCard extends StatelessWidget {
  final FamilyGroup group;
  /// Khi bạn là chủ nhóm mà API trả memberCount = 0, vẫn hiển thị ít nhất 1 thành viên (bạn).
  final String? currentUserId;

  const FamilyGroupCard({
    super.key,
    required this.group,
    this.currentUserId,
  });

  /// Chủ nhóm luôn là ít nhất 1 thành viên; nếu API trả 0 thì hiển thị 1.
  int _effectiveMemberCount() {
    if (currentUserId != null &&
        currentUserId!.isNotEmpty &&
        group.ownerId == currentUserId &&
        group.memberCount < 1) {
      return 1;
    }
    return group.memberCount;
  }

  @override
  Widget build(BuildContext context) {
    final uid = currentUserId ?? '';
    final isOwner = uid.isNotEmpty && group.ownerId == uid;
    final displayMemberCount = _effectiveMemberCount();
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
                      color: AppColors.primary.withValues(alpha:0.3),
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
                              color: AppColors.textGrey.withValues(alpha:0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$displayMemberCount thành viên',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textGrey.withValues(alpha:0.8),
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
                  color: AppColors.textGrey.withValues(alpha:0.6),
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
                color: AppColors.inputBackground.withValues(alpha:0.5),
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
                                color: AppColors.primary.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                metric.icon,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              metric.displayLabel,
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
                          color: AppColors.textGrey.withValues(alpha:0.8),
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
                    color: AppColors.textGrey.withValues(alpha:0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hoạt động: ${StringHelper.formatTimeAgo(group.lastActivity)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey.withValues(alpha:0.8),
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
                    color: Colors.orange.withValues(alpha:0.1),
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

