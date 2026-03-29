import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/core/utils/family_state_helper.dart';
import 'package:fe/core/widgets/confirmation_dialog.dart';
import 'package:fe/data/enums/group_member_status.dart';
import 'package:fe/data/enums/metric_type_extension.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/widgets/family_management_app_bar.dart';
import 'package:fe/presentation/family/widgets/create_group_dialog.dart';
import 'package:fe/presentation/family/widgets/accept_invitation_dialog.dart';
import 'package:fe/presentation/family/widgets/edit_group_permissions_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class FamilyGroupManagementView extends StatefulWidget {
  const FamilyGroupManagementView({super.key});

  @override
  State<FamilyGroupManagementView> createState() =>
      _FamilyGroupManagementViewState();
}

class _FamilyGroupManagementViewState
    extends State<FamilyGroupManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _loadedTabs = {0}; // Track which tabs have been loaded

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch invitations when tab changes
    _tabController.addListener(_onTabChanged);
    // Fetch initial data for first tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<FamilyBloc>();
      final state = bloc.state;
      // Only fetch if not already loaded
      if (state.status == FamilyStatus.initial || 
          state.summary.groups.isEmpty) {
        bloc.add(const FetchFamilyGroups());
      }
      // Preload other tabs data in background
      _preloadTabData(bloc, state);
    });
  }

  void _preloadTabData(FamilyBloc bloc, FamilyState state) {
    // Preload incoming invitations if not loaded
    if (state.incomingInvitations.isEmpty) {
      bloc.add(const FetchIncomingInvitations());
    }
    // Preload outgoing invitations if not loaded
    if (state.outgoingInvitations.isEmpty) {
      bloc.add(const FetchOutgoingInvitations());
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging || !mounted) return;

    final bloc = context.read<FamilyBloc>();
    final state = bloc.state;
    final tabIndex = _tabController.index;
    
    // Only fetch if tab hasn't been loaded yet or data is empty
    // This ensures smooth tab switching without unnecessary loading
    switch (tabIndex) {
      case 1:
        if (!_loadedTabs.contains(1) && state.incomingInvitations.isEmpty) {
          bloc.add(const FetchIncomingInvitations());
          _loadedTabs.add(1);
        }
        break;
      case 2:
        if (!_loadedTabs.contains(2) && state.outgoingInvitations.isEmpty) {
          bloc.add(const FetchOutgoingInvitations());
          _loadedTabs.add(2);
        }
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state.status == FamilyStatus.invitationAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã chấp nhận lời mời thành công'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
          if (state.status == FamilyStatus.invitationDeclined) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã từ chối lời mời'),
                backgroundColor: AppColors.textGrey,
              ),
            );
            // Force refresh incoming invitations to update UI
            context.read<FamilyBloc>().add(const FetchIncomingInvitations());
          }
        },
        child: BlocBuilder<FamilyBloc, FamilyState>(
        builder: (context, state) {
          // Only show loading on initial load, not when switching tabs
          if (FamilyStateHelper.shouldShowLoading(state)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (FamilyStateHelper.shouldShowErrorScreen(state)) {
            return Center(
              child: Text(
                UserFacingError.message(state.errorMessage),
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          // Always show content if we have any data, even if loading in background
          if (FamilyStateHelper.shouldShowContent(state)) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSize.shellMaxWidth),
                child: Column(
                  children: [
                    FamilyManagementAppBar(
                      onCreateGroup: _openCreateGroupDialog,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSize.p16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quản lý nhóm chia sẻ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TabBar(
                            controller: _tabController,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textGrey,
                            indicatorColor: AppColors.primary,
                            tabs: const [
                              Tab(text: 'Nhóm của tôi'),
                              Tab(text: 'Lời mời tham gia'),
                              Tab(text: 'Lời mời đã gửi'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(), // Smooth scrolling
                        children: [
                          _MyGroupsTab(
                            groups: state.summary.groups,
                            onCopyLink: _copyGroupLink,
                            onEditPermissions: _editGroupPermissions,
                          ),
                          _IncomingInvitationsTab(),
                          _OutgoingInvitationsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('Trạng thái không xác định'));
        },
        ),
      ),
    );
  }

  void _openCreateGroupDialog() {
    final bloc = context.read<FamilyBloc>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha:0.5),
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: CreateGroupDialog(
            rootContext: context,
          ),
        );
      },
    );
  }

  void _copyGroupLink(BuildContext context, FamilyGroup group) {
    final link = 'https://healthapp.com/join/${group.id}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép link nhóm'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _editGroupPermissions(BuildContext context, FamilyGroup group) {
    // Show confirmation dialog first
    showDialog<void>(
      context: context,
      builder: (confirmContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa nhóm'),
          content: const Text(
            'Bạn có muốn chỉnh sửa thông tin nhóm này không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(confirmContext);
                // Open edit dialog
                final bloc = context.read<FamilyBloc>();
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) {
                    return BlocProvider.value(
                      value: bloc,
                      child: EditGroupPermissionsDialog(group: group),
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Chỉnh sửa'),
            ),
          ],
        );
      },
    );
  }
}

class _MyGroupsTab extends StatelessWidget {
  final List<FamilyGroup> groups;
  final Function(BuildContext, FamilyGroup) onCopyLink;
  final Function(BuildContext, FamilyGroup) onEditPermissions;

  const _MyGroupsTab({
    required this.groups,
    required this.onCopyLink,
    required this.onEditPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.shellMaxWidth),
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<FamilyBloc>().add(const FetchFamilyGroups());
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: groups.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 64,
                            color: AppColors.textGrey.withValues(alpha:0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có nhóm nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kéo xuống để làm mới',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey.withValues(alpha:0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: AppSize.p16,
                    right: AppSize.p16,
                    top: AppSize.p16,
                    bottom: AppSize.p16 + MediaQuery.of(context).padding.bottom + 100,
                  ),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    return _buildGroupCard(context, groups[index]);
                  },
                ),
        ),
      ),
    );
  }


  Widget _buildGroupCard(BuildContext context, FamilyGroup group) {
    final authUserId = context.read<AuthBloc>().state.user.id;
    final isOwner = authUserId.isNotEmpty && group.ownerId == authUserId;
    // BE GET /groups không trả member_count → 0; chủ nhóm luôn là ít nhất 1 thành viên
    final displayMemberCount = (isOwner && group.memberCount < 1) ? 1 : group.memberCount;
    final dateFormat = DateFormat('yyyy-MM-dd');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppSize.p16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSize.r12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isOwner
                                    ? AppColors.primary
                                    : AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOwner ? 'Chủ nhóm' : 'Thành viên',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isOwner
                                      ? Colors.white
                                      : AppColors.textGrey,
                                ),
                              ),
                            ),
                            if (group.pendingInvitations > 0) ...[
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.mail_outline,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${group.pendingInvitations} lời mời',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isOwner)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () => onCopyLink(context, group),
                          color: AppColors.textGrey,
                          tooltip: 'Sao chép link nhóm',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => onEditPermissions(context, group),
                          color: AppColors.textGrey,
                          tooltip: 'Chỉnh sửa quyền truy cập',
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {},
                          color: AppColors.textGrey,
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, size: 20),
                          onPressed: () {},
                          color: AppColors.textGrey,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$displayMemberCount thành viên • Tạo ${dateFormat.format(group.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              if (group.sharedMetrics.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: group.sharedMetrics.map((metric) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        metric.displayLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textBlack,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
  }
}

class _IncomingInvitationsTab extends StatelessWidget {
  const _IncomingInvitationsTab();

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        // Force refresh when invitation is declined or accepted
        if (state.status == FamilyStatus.invitationDeclined ||
            state.status == FamilyStatus.invitationAccepted) {
          // The list will be automatically updated by BlocBuilder below
          // after FetchIncomingInvitations is dispatched in bloc
        }
      },
      child: BlocBuilder<FamilyBloc, FamilyState>(
        buildWhen: (previous, current) =>
            previous.incomingInvitations != current.incomingInvitations ||
            previous.status != current.status,
        builder: (context, state) {
          // Show empty state immediately if no data, don't wait for loading
          if (state.incomingInvitations.isEmpty && 
              state.status != FamilyStatus.loading) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<FamilyBloc>().add(const FetchIncomingInvitations());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 64,
                        color: AppColors.textGrey.withValues(alpha:0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có lời mời nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kéo xuống để làm mới',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey.withValues(alpha:0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force refresh by clearing cache and fetching again
            context.read<FamilyBloc>().add(const FetchIncomingInvitations());
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: AppSize.p16,
              right: AppSize.p16,
              top: AppSize.p16,
              bottom: AppSize.p16 + MediaQuery.of(context).padding.bottom + 100,
            ),
            itemCount: state.incomingInvitations.length,
            itemBuilder: (context, index) {
              final invitation = state.incomingInvitations[index];
              return _buildIncomingInvitationCard(context, invitation);
            },
          ),
        );
        },
      ),
    );
  }

  Widget _buildIncomingInvitationCard(BuildContext context, IncomingInvitation invitation) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSize.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSize.r12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.groupName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mời bởi: ${invitation.inviterName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invitation.memberCount} thành viên • ${dateFormat.format(invitation.sentAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (invitation.sharedMetrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: invitation.sharedMetrics.map((metric) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    metric.displayLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.textBlack),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showDeclineConfirmationDialog(context, invitation);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final bloc = context.read<FamilyBloc>();
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.black.withValues(alpha:0.5),
                      builder: (dialogContext) {
                        return BlocProvider.value(
                          value: bloc,
                          child: AcceptInvitationDialog(invitation: invitation),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Chấp nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeclineConfirmationDialog(BuildContext context, IncomingInvitation invitation) {
    ConfirmationDialog.showErrorConfirmation(
      context: context,
      title: 'Xác nhận từ chối',
      message: 'Bạn có chắc chắn muốn từ chối lời mời tham gia nhóm "${invitation.groupName}"?',
      confirmText: 'Từ chối',
      onConfirm: () {
        context.read<FamilyBloc>().add(
              DeclineInvitation(groupId: invitation.groupId),
            );
      },
    );
  }

}

class _OutgoingInvitationsTab extends StatelessWidget {
  const _OutgoingInvitationsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      builder: (context, state) {
        // Show empty state immediately if no data, don't wait for loading
        if (state.outgoingInvitations.isEmpty && 
            state.status != FamilyStatus.loading) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<FamilyBloc>().add(const FetchOutgoingInvitations());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_outlined,
                        size: 64,
                        color: AppColors.textGrey.withValues(alpha:0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có lời mời nào được gửi',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kéo xuống để làm mới',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey.withValues(alpha:0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<FamilyBloc>().add(const FetchOutgoingInvitations());
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: AppSize.p16,
              right: AppSize.p16,
              top: AppSize.p16,
              bottom: AppSize.p16 + MediaQuery.of(context).padding.bottom + 100,
            ),
            itemCount: state.outgoingInvitations.length,
            itemBuilder: (context, index) {
              final invitation = state.outgoingInvitations[index];
              return _buildOutgoingInvitationCard(context, invitation);
            },
          ),
        );
      },
    );
  }

  Widget _buildOutgoingInvitationCard(BuildContext context, OutgoingInvitation invitation) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (invitation.status) {
      case GroupMemberStatus.pending:
        statusText = 'Đang chờ';
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case GroupMemberStatus.accepted:
        statusText = 'Đã chấp nhận';
        statusColor = AppColors.primary;
        statusIcon = Icons.check_circle;
        break;
      case GroupMemberStatus.declined:
        statusText = 'Đã từ chối';
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case GroupMemberStatus.revoked:
        statusText = 'Đã hủy';
        statusColor = AppColors.textGrey;
        statusIcon = Icons.block;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSize.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSize.r12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.groupName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      invitation.inviteeEmail.isNotEmpty
                          ? 'Mời: ${invitation.inviteeName} (${invitation.inviteeEmail})'
                          : 'Mời: ${invitation.inviteeName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textBlack,
                      ),
                    ),
                    if (invitation.relationship != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Mối quan hệ: ${invitation.relationship}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Gửi ngày: ${dateFormat.format(invitation.sentAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (invitation.sharedMetrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: invitation.sharedMetrics.map((metric) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    metric.displayLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.textBlack),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

}

