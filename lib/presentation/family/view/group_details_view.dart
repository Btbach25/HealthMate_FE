import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/utils/user_id_utils.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/widgets/confirmation_dialog.dart';
import 'package:fe/core/widgets/loading_widget.dart';
import 'package:fe/core/widgets/error_widget.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/widgets/family_app_bar.dart';
import 'package:fe/presentation/family/widgets/family_member_card.dart';
import 'package:fe/presentation/family/widgets/add_member_modal.dart';
import 'package:fe/presentation/family/widgets/family_member_metrics_dialog.dart';
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
          // Nếu FE đã đánh dấu group này là đã rời/xóa, luôn thoát khỏi màn chi tiết.
          // Tránh bị stuck khi status/group list bị request trễ ghi đè.
          final shouldExit = state.hiddenGroupIds.contains(widget.groupId);
          if (shouldExit && context.mounted && !_didNavigateAway) {
            _didNavigateAway = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã rời nhóm thành công'),
                backgroundColor: AppColors.primary,
              ),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              // Force navigation even if router thinks we're already on /family.
              final ts = DateTime.now().microsecondsSinceEpoch.toString();
              context.go('/family?left=$ts');
            });
            return;
          }

          // Khi rời nhóm, currentGroupId đã bị set null → dùng "nhóm đang xem không còn trong danh sách"
          final leftGroupWeAreViewing = state.status == FamilyStatus.groupLeft &&
              !state.summary.groups.any((g) => g.id == widget.groupId);
          if (leftGroupWeAreViewing) {
            if (!context.mounted || _didNavigateAway) return;
            _didNavigateAway = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã rời nhóm thành công'),
                backgroundColor: AppColors.primary,
              ),
            );
            // Tránh pop nhầm dialog/navigator con: điều hướng thẳng về màn danh sách nhóm.
            Future.microtask(() {
              if (!mounted) return;
              final ts = DateTime.now().microsecondsSinceEpoch.toString();
              context.go('/family?left=$ts');
            });
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
        },
        child: BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            final isCurrentGroup = state.currentGroupId == widget.groupId;
            final waitingForDetails = isCurrentGroup && state.groupDetails == null;
            final waitingForThisGroup = !isCurrentGroup && state.status != FamilyStatus.error;
            // Khi FetchFamilyGroups ghi đè (loaded, currentGroupId=null) → reset để gửi lại fetch
            if (state.status == FamilyStatus.loaded && state.currentGroupId == null) {
              _requestedGroupId = null;
            }
            // Chỉ gửi fetch 1 lần: từ post-frame, không dispatch trong initState → tránh một đống request
            if ((waitingForDetails || waitingForThisGroup) && _requestedGroupId != widget.groupId) {
              _requestedGroupId = widget.groupId;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                context.read<FamilyBloc>().add(FetchGroupDetails(groupId: widget.groupId));
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
                    context.go('/login');
                  } else {
                    context.read<FamilyBloc>().add(
                          FetchGroupDetails(groupId: widget.groupId),
                        );
                  }
                },
              );
            }

            if ((state.status == FamilyStatus.groupDetailsLoaded ||
                    state.status == FamilyStatus.memberInvited ||
                    state.status == FamilyStatus.ownershipTransferred) &&
                state.groupDetails != null &&
                isCurrentGroup) {
              final details = state.groupDetails!;
              final authUser = context.read<AuthBloc>().state.user;
              final isCurrentUserOwner =
                  authUser.id.isNotEmpty && sameUserId(details.group.ownerId, authUser.id);
              final ownerAlreadyInList =
                  details.members.any((m) => sameUserId(m.userId, authUser.id));
              final groupMetricsPlaceholder = details.group.sharedMetrics;

              final List<FamilyMember> effectiveMembers = [];
              if (isCurrentUserOwner && !ownerAlreadyInList) {
                effectiveMembers.add(
                  FamilyMember(
                    id: authUser.id,
                    userId: authUser.id,
                    groupId: details.group.id,
                    name: authUser.name.isNotEmpty ? authUser.name : 'Bạn',
                    email: authUser.email,
                    age: null,
                    relationship: null,
                    avatar: authUser.picture,
                    healthStatus: HealthStatus.healthy,
                    lastUpdated: DateTime.now(),
                    healthConditions: const [],
                    sharedMetrics: groupMetricsPlaceholder,
                    createdAt: DateTime.now(),
                  ),
                );
              }
              for (final m in details.members) {
                if (sameUserId(m.userId, authUser.id)) {
                  effectiveMembers.add(
                    m.copyWith(
                      name: authUser.name.isNotEmpty ? authUser.name : 'Bạn',
                      email: authUser.email,
                      avatar: authUser.picture,
                      sharedMetrics: m.sharedMetrics.isEmpty
                          ? groupMetricsPlaceholder
                          : m.sharedMetrics,
                    ),
                  );
                } else {
                  effectiveMembers.add(m);
                }
              }
              final displayMemberCount = effectiveMembers.length;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSize.shellMaxWidth),
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
                        // Members list (đã gộp chủ nhóm vào nếu API chưa trả)
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
                                onViewMetrics: () {
                                  FamilyMemberMetricsDialog.show(
                                    context: context,
                                    member: member,
                                  );
                                },
                              ),
                            )),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
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
    final authUser = context.read<AuthBloc>().state.user;
    final isOwner =
        authUser.id.isNotEmpty && sameUserId(details.group.ownerId, authUser.id);
    // Filter out current user from members list (dùng đúng user.id thay vì placeholder)
    final otherMembers =
        details.members.where((m) => !sameUserId(m.userId, authUser.id)).toList();
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
        message: 'Hiện tại chỉ còn bạn trong nhóm.\n'
            'Nếu bạn rời nhóm, nhóm sẽ bị xóa hoàn toàn.\n\n'
            'Bạn có chắc chắn muốn tiếp tục?',
        confirmText: 'Xóa nhóm',
        confirmColor: Colors.red,
        onConfirm: () {
          context.read<FamilyBloc>().add(DeleteGroup(groupId: details.group.id));
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
        context.read<FamilyBloc>().add(
              LeaveGroup(groupId: groupId),
            );
        // Navigation will be handled by BlocListener
      },
    );
  }
}

