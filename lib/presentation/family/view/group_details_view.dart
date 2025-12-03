import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/widgets/loading_widget.dart';
import 'package:fe/core/widgets/error_widget.dart';
import 'package:fe/data/enums/group_member_role.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/widgets/family_app_bar.dart';
import 'package:fe/presentation/family/widgets/family_member_card.dart';
import 'package:fe/presentation/family/widgets/add_member_modal.dart';
import 'package:fe/presentation/family/widgets/transfer_ownership_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GroupDetailsView extends StatefulWidget {
  final String groupId;

  const GroupDetailsView({super.key, required this.groupId});

  @override
  State<GroupDetailsView> createState() => _GroupDetailsViewState();
}

class _GroupDetailsViewState extends State<GroupDetailsView> {
  @override
  void initState() {
    super.initState();
    context.read<FamilyBloc>().add(FetchGroupDetails(groupId: widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<FamilyBloc, FamilyState>(
        listener: (context, state) {
          final isCurrentGroup =
              state.currentGroupId == widget.groupId;
          if (state.status == FamilyStatus.groupLeft && isCurrentGroup) {
            if (context.mounted) {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã rời nhóm thành công'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          }
          if (state.status == FamilyStatus.memberRemoved && isCurrentGroup) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xóa thành viên khỏi nhóm'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        },
        child: BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            if (state.status == FamilyStatus.initial ||
                state.status == FamilyStatus.loading) {
              return const LoadingWidget(
                message: 'Đang tải thông tin nhóm...',
                isFullScreen: true,
              );
            }

            if (state.status == FamilyStatus.error) {
              return ErrorDisplayWidget(
                message: state.errorMessage ?? 'Đã có lỗi xảy ra',
                onRetry: () {
                  context.read<FamilyBloc>().add(
                        FetchGroupDetails(groupId: widget.groupId),
                      );
                },
              );
            }

            final isCurrentGroup =
                state.currentGroupId == widget.groupId;

            if ((state.status == FamilyStatus.groupDetailsLoaded ||
                    state.status == FamilyStatus.memberInvited ||
                    state.status == FamilyStatus.ownershipTransferred) &&
                state.groupDetails != null &&
                isCurrentGroup) {
              final details = state.groupDetails!;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSize.maxWidth),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSize.p20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FamilyAppBar(),
                        const SizedBox(height: AppSize.spacing24),
                        // Navigation bar
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => context.pop(),
                              color: AppColors.textBlack,
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                context.push('/family');
                              },
                              icon: const Icon(Icons.people_outline, size: 18),
                              label: const Text('Chọn nhóm khác'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textBlack,
                              ),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: () {
                                _showLeaveGroupDialog(context, details);
                              },
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('Rời nhóm'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSize.spacing24),
                        // Title
                        const Text(
                          'Thành viên gia đình',
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: AppSize.spacing8),
                        Text(
                          'Nhóm: ${details.group.name} • ${details.group.memberCount} thành viên',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: AppSize.spacing24),
                        // Add member button
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppSize.r12),
                              boxShadow: AppColors.buttonShadow,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showAddMemberModal(context, details.group.id);
                              },
                              icon: const Icon(Icons.add, color: Colors.white, size: AppSize.icon20),
                              label: Text(
                                'Thêm vào ${details.group.name}',
                                style: AppTextStyles.buttonLarge,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: AppSize.p16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSize.r12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSize.spacing32),
                        // Members list
                        ...details.members.map((member) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FamilyMemberCard(
                                member: member,
                                isOwner: details.group.userRole == GroupMemberRole.admin,
                                groupId: details.group.id,
                              ),
                            )),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                      ],
                    ),
                  ),
                ),
              );
            }

            return const LoadingWidget(
              message: 'Đang chuẩn bị dữ liệu nhóm...',
              isFullScreen: true,
            );
          },
        ),
      ),
    );
  }

  void _showAddMemberModal(BuildContext context, String groupId) {
    final bloc = context.read<FamilyBloc>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: AddMemberModal(groupId: groupId),
        );
      },
    );
  }

  void _showLeaveGroupDialog(BuildContext context, dynamic details) {
    final isOwner = details.group.userRole == GroupMemberRole.admin;
    // Filter out current user from members list
    final otherMembers = details.members.where((m) => m.userId != 'current-user-id').toList();
    final hasOtherMembers = otherMembers.isNotEmpty;

    if (isOwner && hasOtherMembers) {
      // Show transfer ownership modal first
      showDialog(
        context: context,
        builder: (context) => TransferOwnershipModal(
          groupId: details.group.id,
          members: otherMembers,
        ),
      );
    } else if (isOwner && !hasOtherMembers) {
      // Show warning that cannot leave without transferring
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Không thể rời nhóm'),
          content: const Text(
            'Bạn cần chuyển quyền chủ nhóm cho thành viên khác trước khi rời nhóm. Hiện tại nhóm chỉ có bạn là thành viên.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } else {
      // Show confirmation dialog for non-owners
      _showLeaveConfirmationDialog(context, details.group.id);
    }
  }

  void _showLeaveConfirmationDialog(BuildContext context, String groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời nhóm'),
        content: const Text('Bạn có chắc chắn muốn rời nhóm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog first
              context.read<FamilyBloc>().add(
                    LeaveGroup(groupId: groupId),
                  );
              // Navigation will be handled by BlocListener
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Xác nhận rời nhóm'),
          ),
        ],
      ),
    );
  }
}

