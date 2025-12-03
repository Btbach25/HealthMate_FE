import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final bool isOwner;
  final String groupId;

  const FamilyMemberCard({
    super.key,
    required this.member,
    this.isOwner = false,
    required this.groupId,
  });

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
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

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.good:
        return AppColors.primary;
      case HealthStatus.needsAttention:
        return Colors.orange;
      case HealthStatus.healthy:
        return AppColors.primary;
    }
  }

  Color _getStatusBgColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.good:
        return AppColors.tagImportantBg;
      case HealthStatus.needsAttention:
        return AppColors.tagWarningBg;
      case HealthStatus.healthy:
        return AppColors.tagImportantBg;
    }
  }

  String _getStatusLabel(HealthStatus status) {
    switch (status) {
      case HealthStatus.good:
        return 'Tốt';
      case HealthStatus.needsAttention:
        return 'Cần chú ý';
      case HealthStatus.healthy:
        return 'Khỏe mạnh';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(member.healthStatus);
    final statusBgColor = _getStatusBgColor(member.healthStatus);

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
                    _getInitials(member.name),
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
                        if (isOwner && member.userId != 'current-user-id')
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
                        color: AppColors.textGrey.withOpacity(0.8),
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
                  _getStatusLabel(member.healthStatus),
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
                    color: AppColors.textGrey.withOpacity(0.8),
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
                  color: AppColors.textGrey.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Cập nhật: ${dateFormat.format(member.lastUpdated!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey.withOpacity(0.8),
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
                        color: AppColors.textGrey.withOpacity(0.8),
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
                  onPressed: () {},
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
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_outline, size: 18),
                  label: const Text('Theo dõi'),
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa thành viên'),
          content: Text(
            'Bạn có chắc chắn muốn xóa "${member.name}" khỏi nhóm không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<FamilyBloc>().add(
                      RemoveMember(
                        groupId: groupId,
                        memberId: member.id,
                      ),
                    );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }
}

