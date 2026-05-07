import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/utils/user_id_utils.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/widgets/confirmation_dialog.dart';
import 'package:fe/core/widgets/loading_widget.dart';
import 'package:fe/core/widgets/error_widget.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/family/view/group_details_members.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/widgets/family_app_bar.dart';
import 'package:fe/presentation/family/widgets/family_member_card.dart';
import 'package:fe/presentation/family/widgets/add_member_modal.dart';
import 'package:fe/presentation/family/widgets/family_member_metrics_dialog.dart';
import 'package:fe/presentation/family/widgets/edit_member_permissions_dialog.dart';
import 'package:fe/presentation/family/widgets/group_medication_share_dialog.dart';
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
  String? _requestedGroupId;
  bool _didNavigateAway = false;

  @override
  void didUpdateWidget(covariant GroupDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) _requestedGroupId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (_shouldExitGroupDetailAfterLeave(state, widget.groupId)) {
            if (context.mounted && !_didNavigateAway) {
              _didNavigateAway = true;
              _showLeftGroupSuccessAndGoToFamilyList(context);
            }
            return;
          }
          if (state.status == FamilyStatus.memberRemoved &&
              state.currentGroupId == widget.groupId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xóa thành viên khỏi nhóm'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
          if (state.status == FamilyStatus.joinRequestApproved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã duyệt yêu cầu, thành viên đã tham gia nhóm'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.status == FamilyStatus.joinRequestRejected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã từ chối yêu cầu tham gia'),
                backgroundColor: AppColors.textGrey,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            final isCurrentGroup = state.currentGroupId == widget.groupId;
            final waitingForDetails =
                isCurrentGroup && state.groupDetails == null;
            final waitingForThisGroup =
                !isCurrentGroup && state.status != FamilyStatus.error;
            // Khi FetchFamilyGroups ghi đè (loaded, currentGroupId=null) → reset để gửi lại fetch
            if (state.status == FamilyStatus.loaded &&
                state.currentGroupId == null) {
              _requestedGroupId = null;
            }
            // Chỉ gửi fetch 1 lần: từ post-frame, không dispatch trong initState → tránh một đống request
            if ((waitingForDetails || waitingForThisGroup) &&
                _requestedGroupId != widget.groupId) {
              _requestedGroupId = widget.groupId;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                context.read<FamilyBloc>().add(
                  FetchGroupDetails(groupId: widget.groupId),
                );
              });
            }

            if (state.status == FamilyStatus.initial ||
                state.status == FamilyStatus.loading ||
                (waitingForDetails && state.status != FamilyStatus.error) ||
                waitingForThisGroup) {
              return const LoadingWidget(
                message: 'Đang tải thông tin nhóm...',
                isFullScreen: true,
              );
            }

            if (state.status == FamilyStatus.error) {
              return ErrorDisplayWidget(
                message: state.errorMessage ?? 'Đã có lỗi xảy ra',
                onRetry: () {
                  if (state.isSessionExpired) {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  } else {
                    context.read<FamilyBloc>().add(
                      FetchGroupDetails(groupId: widget.groupId),
                    );
                  }
                },
              );
            }

            if (state.groupDetails != null &&
                isCurrentGroup &&
                state.status != FamilyStatus.error &&
                state.status != FamilyStatus.initial &&
                state.status != FamilyStatus.loading) {
              final details = state.groupDetails!;
              final authUser = context.read<AuthBloc>().state.user;

              void tryOpenMemberMetrics(FamilyMember member) {
                if (member.sharedMetrics.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${member.name} chưa chia sẻ chỉ số trong nhóm hoặc bạn chưa được cấp quyền xem.',
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                FamilyMemberMetricsDialog.show(
                  context: context,
                  member: member,
                  groupId: details.group.id,
                );
              }
              final isCurrentUserOwner =
                  authUser.id.isNotEmpty &&
                  sameUserId(details.group.ownerId, authUser.id);
              final ownerAlreadyInList = details.members.any(
                (m) => sameUserId(m.userId, authUser.id),
              );
              final effectiveMembers = buildEffectiveMembersForGroupDetails(
                details: details,
                authUser: authUser,
                isCurrentUserOwner: isCurrentUserOwner,
                ownerAlreadyInList: ownerAlreadyInList,
              );
              final displayMemberCount = effectiveMembers.length;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSize.shellMaxWidth,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSize.p20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FamilyAppBar(),
                        const SizedBox(height: AppSize.spacing24),
                        // Navigation bar
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 360;
                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        onPressed: () => context.pop(),
                                        color: AppColors.textBlack,
                                      ),
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            context.push('/family');
                                          },
                                          icon: const Icon(
                                            Icons.people_outline,
                                            size: 18,
                                          ),
                                          label: const Text('Chọn nhóm khác'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.textBlack,
                                            alignment: Alignment.centerLeft,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        _showLeaveGroupDialog(context, details);
                                      },
                                      icon: const Icon(Icons.logout, size: 18),
                                      label: const Text('Rời nhóm'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange,
                                        side:
                                            const BorderSide(color: Colors.orange),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Row(
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
                            );
                          },
                        ),
                        const SizedBox(height: AppSize.spacing24),
                        // Title
                        const Text(
                          'Thành viên gia đình',
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: AppSize.spacing8),
                        Text(
                          'Nhóm: ${details.group.name} • $displayMemberCount thành viên',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: AppColors.textGrey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Thông tin trong nhóm chỉ nhằm hỗ trợ theo dõi; không thay thế tư vấn y tế. Hãy luôn tuân theo chỉ định của cơ sở khám chữa bệnh.',
                                  style: AppTextStyles.caption.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSize.spacing24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.medication_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Chia sẻ nhắc uống thuốc',
                                      style: AppTextStyles.labelLarge,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        details.group.medicationSharingAllowed
                                            ? () async {
                                                final ok = await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => GroupMedicationShareDialog(
                                                    groupId: details.group.id,
                                                    members: details.members,
                                                    currentUserId: authUser.id,
                                                  ),
                                                );
                                                if (ok == true &&
                                                    context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Đã cập nhật chia sẻ nhắc thuốc cho nhóm',
                                                      ),
                                                      backgroundColor:
                                                          AppColors.primary,
                                                      behavior:
                                                          SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              }
                                            : null,
                                    child: const Text('Quản lý tại đây'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                details.group.medicationSharingAllowed
                                    ? 'Nhấn "Quản lý tại đây" để chọn từng loại thuốc và thành viên nhận nhắc. Chỉ thành viên đủ điều kiện theo quyền nhóm và quyền cá nhân mới xuất hiện.'
                                    : 'Nhóm chưa bật chia sẻ nhắc uống thuốc. Hãy chỉnh quyền chung của nhóm trước, rồi mới thiết lập chia sẻ nhắc thuốc.',
                                style: AppTextStyles.caption.copyWith(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSize.spacing20),
                        // Khu vực "Yêu cầu chờ duyệt" — chỉ chủ nhóm thấy.
                        // Dữ liệu thực từ GET /groups/:id/pending-approvals.
                        if (isCurrentUserOwner)
                          _PendingApprovalsSection(
                            groupId: details.group.id,
                          ),
                        if (isCurrentUserOwner)
                          const SizedBox(height: AppSize.spacing20),
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
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: AppSize.icon20,
                              ),
                              label: Text(
                                'Thêm vào ${details.group.name}',
                                style: AppTextStyles.buttonLarge,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSize.p16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSize.r12,
                                  ),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSize.spacing32),
                        ...effectiveMembers.map((member) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FamilyMemberCard(
                                member: member,
                                // BE dùng owner_id, role "owner". Dùng ownerId để chắc chắn đúng.
                                isOwner: isCurrentUserOwner,
                                isGroupOwner:
                                    sameUserId(member.userId, details.group.ownerId),
                                groupId: details.group.id,
                                isCurrentUser: sameUserId(member.userId, authUser.id),
                                onViewMetrics: () => tryOpenMemberMetrics(member),
                                onFollow: () => tryOpenMemberMetrics(member),
                                onEditPermissions: isCurrentUserOwner &&
                                        !sameUserId(member.userId, authUser.id)
                                    ? () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (dialogContext) {
                                            return BlocProvider.value(
                                              value: context.read<FamilyBloc>(),
                                              child: EditMemberPermissionsDialog(
                                                groupId: details.group.id,
                                                member: member,
                                                globalMetrics:
                                                    details.group.sharedMetrics,
                                                groupMedicationReminderShareAllowed:
                                                    details.group.medicationSharingAllowed,
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    : null,
                              ),
                            )),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 100,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Fallback: trạng thái không xác định (hiếm), vẫn coi như đang tải
            return const LoadingWidget(
              message: 'Đang tải thông tin nhóm...',
              isFullScreen: true,
            );
          },
        ),
      ),
    );
  }

  void _showAddMemberModal(BuildContext context, String groupId) {
    final bloc = context.read<FamilyBloc>();
    final allowedMetrics = bloc.state.groupDetails?.group.sharedMetrics ?? const [];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: AddMemberModal(
            groupId: groupId,
            groupAllowedMetrics: allowedMetrics,
          ),
        );
      },
    );
  }

  void _showLeftGroupSuccessAndGoToFamilyList(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã rời nhóm thành công'),
        backgroundColor: AppColors.primary,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.mounted) return;
      final ts = DateTime.now().microsecondsSinceEpoch.toString();
      context.go('/family?left=$ts');
    });
  }

  void _showLeaveGroupDialog(BuildContext context, GroupDetails details) {
    final authUser = context.read<AuthBloc>().state.user;
    final isOwner =
        authUser.id.isNotEmpty &&
        sameUserId(details.group.ownerId, authUser.id);
    // Filter out current user from members list (dùng đúng user.id thay vì placeholder)
    final otherMembers = details.members
        .where((m) => !sameUserId(m.userId, authUser.id))
        .toList();
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
      // Chủ nhóm và chỉ còn một mình trong nhóm: rời nhóm = xoá nhóm (confirm trước)
      ConfirmationDialog.showConfirmation(
        context: context,
        title: 'Xóa nhóm gia đình',
        message:
            'Hiện tại chỉ còn bạn trong nhóm.\n'
            'Nếu bạn rời nhóm, nhóm sẽ bị xóa hoàn toàn.\n\n'
            'Bạn có chắc chắn muốn tiếp tục?',
        confirmText: 'Xóa nhóm',
        confirmColor: Colors.red,
        onConfirm: () {
          context.read<FamilyBloc>().add(
            DeleteGroup(groupId: details.group.id),
          );
          // Đóng dialog, điều hướng sẽ được BlocListener xử lý ở nơi khác (family view)
          Navigator.of(context).pop();
        },
      );
    } else {
      // Show confirmation dialog for non-owners
      _showLeaveConfirmationDialog(context, details.group.id);
    }
  }

  void _showLeaveConfirmationDialog(BuildContext context, String groupId) {
    ConfirmationDialog.showConfirmation(
      context: context,
      title: 'Rời nhóm',
      message: 'Bạn có chắc chắn muốn rời nhóm này?',
      confirmText: 'Xác nhận rời nhóm',
      confirmColor: Colors.orange,
      onConfirm: () {
        context.read<FamilyBloc>().add(LeaveGroup(groupId: groupId));
        // Navigation will be handled by BlocListener
      },
    );
  }
}

/// Khu vực hiển thị yêu cầu đang chờ chủ nhóm duyệt.
/// Dữ liệu từ GET /groups/:id/pending-approvals (dispatch FetchPendingApprovals khi mount).
class _PendingApprovalsSection extends StatefulWidget {
  final String groupId;

  const _PendingApprovalsSection({required this.groupId});

  @override
  State<_PendingApprovalsSection> createState() =>
      _PendingApprovalsSectionState();
}

class _PendingApprovalsSectionState extends State<_PendingApprovalsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<FamilyBloc>()
          .add(FetchPendingApprovals(groupId: widget.groupId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      buildWhen: (p, c) =>
          p.pendingApprovals != c.pendingApprovals ||
          p.status != c.status,
      builder: (context, state) {
        final pendingList = state.pendingApprovals
            .where((inv) => inv.groupId == widget.groupId)
            .toList();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.deepOrange.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSize.r12),
            border: Border.all(
              color: Colors.deepOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      size: 18,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Yêu cầu chờ duyệt',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.deepOrange,
                      ),
                    ),
                    if (pendingList.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pendingList.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (pendingList.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Text(
                    'Không có yêu cầu nào đang chờ duyệt.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                )
              else
                ...pendingList.map(
                  (inv) => _PendingApprovalTile(
                    invitation: inv,
                    groupId: widget.groupId,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingApprovalTile extends StatelessWidget {
  final OutgoingInvitation invitation;
  final String groupId;

  const _PendingApprovalTile({
    required this.invitation,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final inviteeName = invitation.inviteeName.isNotEmpty
        ? invitation.inviteeName
        : invitation.inviteeEmail;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inviteeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                if (invitation.inviteeEmail.isNotEmpty &&
                    invitation.inviteeName.isNotEmpty)
                  Text(
                    invitation.inviteeEmail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              context.read<FamilyBloc>().add(
                    ApproveJoinRequest(
                      groupId: groupId,
                      memberId: invitation.invitee?.id ?? '',
                    ),
                  );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Duyệt', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: () {
              context.read<FamilyBloc>().add(
                    RejectJoinRequest(
                      groupId: groupId,
                      memberId: invitation.invitee?.id ?? '',
                    ),
                  );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Từ chối', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Thoát màn chi tiết khi FE ẩn group (rời/xóa) hoặc bloc báo đã rời và group không còn trong list.
bool _shouldExitGroupDetailAfterLeave(FamilyState state, String groupId) {
  if (state.hiddenGroupIds.contains(groupId)) return true;
  return state.status == FamilyStatus.groupLeft &&
      !state.summary.groups.any((g) => g.id == groupId);
}
