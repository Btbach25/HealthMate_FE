import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/string_helper.dart';
import 'package:fe/core/widgets/clickable.dart';
import 'package:fe/data/enums/metric_type_extension.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Thẻ một nhóm trong danh sách ở tab Gia đình. Bấm vào mở `/family/group/:id`.
/// Nhãn "Chủ nhóm"/"Thành viên" suy ra từ [currentUserId] so với `group.ownerId`.
class FamilyGroupCard extends StatelessWidget {
  final FamilyGroup group;
  final String? currentUserId;

  const FamilyGroupCard({
    super.key,
    required this.group,
    this.currentUserId,
  });

  /// BE GET /groups không trả member_count đúng → luôn hiển thị ≥ 1 vì user đang ở trong nhóm.
  int get _effectiveMemberCount =>
      group.memberCount < 1 ? 1 : group.memberCount;

  @override
  Widget build(BuildContext context) {
    final uid = currentUserId ?? '';
    final isOwner = uid.isNotEmpty && group.ownerId == uid;
    final displayMemberCount = _effectiveMemberCount;
    final visibleMetrics = group.sharedMetrics.take(3).toList();
    final remainingMetrics = group.sharedMetrics.length - visibleMetrics.length;

    return Clickable(
      onTap: () => context.push('/family/group/${group.id}'),
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
            // ── Header row ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSize.p12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSize.r12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
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
                      Text(group.name, style: AppTextStyles.h4),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: AppColors.textGrey.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$displayMemberCount thành viên',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textGrey.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                    color: AppColors.textGrey.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ),

            // ── Shared metrics chips ────────────────────────────────────
            if (visibleMetrics.isNotEmpty ||
                group.medicationSharingAllowed) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...visibleMetrics.map(
                      (metric) => _MetricChip(
                        icon: metric.icon,
                        label: metric.displayLabel,
                      ),
                    ),
                    if (remainingMetrics > 0)
                      _OverflowChip(count: remainingMetrics),
                    if (group.medicationSharingAllowed)
                      const _MetricChip(
                        icon: Icons.medication_outlined,
                        label: 'Nhắc nhở uống thuốc',
                      ),
                  ],
                ),
              ),
            ],

            // ── Footer row ──────────────────────────────────────────────
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textGrey.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hoạt động: ${StringHelper.formatTimeAgo(group.lastActivity)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey.withValues(alpha: 0.8),
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
                      color: Colors.orange.withValues(alpha: 0.1),
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

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverflowChip extends StatelessWidget {
  final int count;

  const _OverflowChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '+$count khác',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textGrey.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
