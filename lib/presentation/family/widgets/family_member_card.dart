import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/string_helper.dart';
import 'package:fe/core/widgets/confirmation_dialog.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/health_status_extension.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final bool isOwner;
  final bool isGroupOwner;
  final String groupId;
  /// True khi đây là thẻ của chính bạn (chủ nhóm) → ẩn nút xóa, dùng "Rời nhóm" thay.
  final bool isCurrentUser;
  /// Bấm "Xem chỉ số" (nếu null thì hiện SnackBar "đang phát triển").
  final VoidCallback? onViewMetrics;
  /// Bấm "Theo dõi" (nếu null thì hiện SnackBar "đang phát triển").
  final VoidCallback? onFollow;
  /// Bấm "Chỉnh quyền" cho thành viên (chỉ chủ nhóm).
  final VoidCallback? onEditPermissions;

  const FamilyMemberCard({
    super.key,
    required this.member,
    this.isOwner = false,
    this.isGroupOwner = false,
    required this.groupId,
    this.isCurrentUser = false,
    this.onViewMetrics,
    this.onFollow,
    this.onEditPermissions,
  });




  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = member.healthStatus.color;
    final statusBgColor = member.healthStatus.backgroundColor;
    final isSelfCard = isCurrentUser;
    final showEditPermissions = onEditPermissions != null && !isSelfCard;
    final secondaryLabel = isSelfCard
        ? 'Đã chia sẻ'
        : (showEditPermissions ? 'Chỉnh quyền' : 'Theo dõi');
    final secondaryIcon = isSelfCard
        ? Icons.share_outlined
        : (showEditPermissions ? Icons.tune_rounded : Icons.favorite_outline);

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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    StringHelper.getInitials(member.name),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: AppTextStyles.h4,
                          ),
                        ),
                        if (isGroupOwner)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Chủ nhóm',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        if (isOwner && !isCurrentUser && member.userId != 'current-user-id')
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _showDeleteMemberDialog(context),
                            color: AppColors.error,
                            tooltip: 'Xóa thành viên',
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.relationship ?? ''}${member.relationship != null && member.age != null ? ' • ' : ''}${member.age != null ? '${member.age} tuổi' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey.withValues(alpha:0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member.healthStatus.displayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Chia sẻ ${member.sharedMetrics.length} chỉ số',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey.withValues(alpha:0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (member.lastUpdated != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 14,
                  color: AppColors.textGrey.withValues(alpha:0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Cập nhật: ${dateFormat.format(member.lastUpdated!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey.withValues(alpha:0.8),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Tình trạng:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
            if (member.healthConditions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: member.healthConditions.map((condition) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      condition,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey.withValues(alpha:0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (onViewMetrics != null) {
                      onViewMetrics!();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Xem chỉ số của ${member.name}: tính năng đang phát triển'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: const Text('Xem chỉ số'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textBlack,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (isSelfCard) {
                      if (onViewMetrics != null) {
                        onViewMetrics!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bạn đang chia sẻ các chỉ số đã chọn trong nhóm'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else if (showEditPermissions) {
                      onEditPermissions!();
                    } else if (onFollow != null) {
                      onFollow!();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Theo dõi ${member.name}: tính năng đang phát triển'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: Icon(secondaryIcon, size: 18),
                  label: Text(secondaryLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textBlack,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteMemberDialog(BuildContext context) {
    ConfirmationDialog.showErrorConfirmation(
      context: context,
      title: 'Xác nhận xóa thành viên',
      message: 'Bạn có chắc chắn muốn xóa "${member.name}" khỏi nhóm không?',
      confirmText: 'Xóa',
      onConfirm: () {
        context.read<FamilyBloc>().add(
              RemoveMember(
                groupId: groupId,
                memberId: member.id,
              ),
            );
      },
    );
  }
}

