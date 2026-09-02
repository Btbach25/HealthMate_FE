import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/family_state_helper.dart';
import 'package:fe/core/utils/toast_utils.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/core/widgets/confirmation_dialog.dart';
import 'package:fe/data/enums/group_member_status.dart';
import 'package:fe/data/enums/metric_type_extension.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/data/repositories/family_repository.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/widgets/accept_invitation_dialog.dart';
import 'package:fe/presentation/family/widgets/create_group_dialog.dart';
import 'package:fe/presentation/family/widgets/edit_group_permissions_dialog.dart';
import 'package:fe/presentation/family/widgets/family_management_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

const _kRefreshTimeout = Duration(seconds: 5);
const _kDialogBarrierAlpha = 0.5;
const _kEmptyStateHeightFactor = 0.6;

/// Bắn [event] rồi chờ bloc thoát khỏi `loading` để `RefreshIndicator` biết lúc
/// nào thu vòng xoay. Quá hạn thì thôi — thà kết thúc animation còn hơn treo mãi.
Future<void> _dispatchAndAwaitFamilyRefresh(
  BuildContext context,
  FamilyEvent event,
) async {
  final bloc = context.read<FamilyBloc>();
  bloc.add(event);
  try {
    await bloc.stream
        .timeout(_kRefreshTimeout)
        .firstWhere((s) => s.status != FamilyStatus.loading);
  } catch (_) {
    // Ignore timeout: RefreshIndicator can finish gracefully.
  }
}

/// Màn quản lý nhóm — route `/family/manage`, mở từ nút "Quản lý" ở tab Gia đình.
///
/// Ba tab: "Nhóm của tôi" (sửa quyền chung, chỉ chủ nhóm mới thấy nút sửa/sao chép
/// link), "Lời mời tham gia" (lời mời gửi tới mình — chấp nhận sẽ chuyển sang chờ
/// chủ nhóm duyệt) và "Lời mời đã gửi" (theo dõi trạng thái lời mời mình đã gửi).
///
/// Dữ liệu hai tab lời mời được nạp lười lúc người dùng mở tab, không preload cùng
/// lúc với danh sách nhóm để tránh ba request song song làm chậm tab đầu.
class FamilyGroupManagementView extends StatefulWidget {
  const FamilyGroupManagementView({super.key});

  @override
  State<FamilyGroupManagementView> createState() =>
      _FamilyGroupManagementViewState();
}

class _FamilyGroupManagementViewState extends State<FamilyGroupManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Các tab đã nạp dữ liệu ít nhất một lần; tab 0 nạp sẵn cùng màn hình.
  final Set<int> _loadedTabs = {0};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<FamilyBloc>();
      final state = bloc.state;
      if (state.status == FamilyStatus.initial ||
          state.summary.groups.isEmpty) {
        bloc.add(const FetchFamilyGroups());
      }
      // Không preload lời mời ngay: tránh 3 request song song (groups + 2 invitation) làm chậm tạo nhóm / tab đầu. Hai tab kia tự fetch khi user mở (_onTabChanged).
    });
  }

  /// Nạp lười dữ liệu cho tab vừa mở, mỗi tab đúng một lần, và chỉ khi đang rỗng —
  /// nhờ vậy chuyển qua lại giữa các tab không nhấp nháy loading.
  void _onTabChanged() {
    if (_tabController.indexIsChanging || !mounted) return;

    final bloc = context.read<FamilyBloc>();
    final state = bloc.state;
    final tabIndex = _tabController.index;

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
            ToastUtils.showCustomToast(
              context,
              'Đã gửi yêu cầu tham gia, đang chờ chủ nhóm duyệt.',
              ToastType.info,
            );
          }
          if (state.status == FamilyStatus.invitationDeclined) {
            ToastUtils.showCustomToast(
              context,
              'Đã từ chối lời mời',
              ToastType.info,
            );
          }
        },
        child: BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            // Chỉ chặn màn hình lúc tải lần đầu; đổi tab thì giữ nguyên nội dung cũ.
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

            // Có dữ liệu là hiển thị, kể cả khi vẫn còn request chạy nền.
            if (FamilyStateHelper.shouldShowContent(state)) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSize.shellMaxWidth,
                  ),
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
                          physics: const BouncingScrollPhysics(),
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
      barrierColor: Colors.black.withValues(alpha: _kDialogBarrierAlpha),
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

  /// Sao chép link mời vào clipboard. Lưu ý: domain đang hard-code, chưa gắn với
  /// deep link thật của ứng dụng.
  void _copyGroupLink(BuildContext context, FamilyGroup group) {
    final link = 'https://healthapp.com/join/${group.id}';
    Clipboard.setData(ClipboardData(text: link));
    ToastUtils.showCustomToast(
      context,
      'Đã sao chép link nhóm',
      ToastType.success,
    );
  }

  /// Mở [EditGroupPermissionsDialog]. Nút gọi hàm này chỉ hiện với chủ nhóm.
  void _editGroupPermissions(BuildContext context, FamilyGroup group) {
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
  }
}

/// Tab "Nhóm của tôi": mọi nhóm người dùng đang tham gia.
/// Nút sao chép link và sửa nhóm chỉ hiện khi người dùng là chủ nhóm.
class _MyGroupsTab extends StatelessWidget {
  final List<FamilyGroup> groups;
  final Function(BuildContext, FamilyGroup) onCopyLink;
  final Function(BuildContext, FamilyGroup) onEditPermissions;

  const _MyGroupsTab({
    required this.groups,
    required this.onCopyLink,
    required this.onEditPermissions,
  });

  Future<void> _refreshGroups(BuildContext context) async {
    await _dispatchAndAwaitFamilyRefresh(context, const FetchFamilyGroups());
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.shellMaxWidth),
        child: RefreshIndicator(
          onRefresh: () => _refreshGroups(context),
          child: groups.isEmpty
              ? _RefreshableEmptyState(
                  onRefresh: () => _refreshGroups(context),
                  icon: Icons.group_outlined,
                  title: 'Chưa có nhóm nào',
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: AppSize.p16,
                    right: AppSize.p16,
                    top: AppSize.p16,
                    bottom:
                        AppSize.p16 +
                        MediaQuery.of(context).padding.bottom +
                        AppSize.bottomTabSafeInset,
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

  static final _groupDateFormat = DateFormat('dd/MM/yyyy');

  Widget _buildGroupCard(BuildContext context, FamilyGroup group) {
    final authUserId = context.read<AuthBloc>().state.user.id;
    final isOwner = authUserId.isNotEmpty && group.ownerId == authUserId;
    final displayMemberCount = group.memberCount < 1 ? 1 : group.memberCount;

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
                      tooltip: 'Chỉnh sửa nhóm',
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$displayMemberCount thành viên • Tạo ${_groupDateFormat.format(group.createdAt)}',
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
          ] else if (group.medicationSharingAllowed) ...[
            const SizedBox(height: 12),
          ],
          if (group.medicationSharingAllowed)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Nhắc nhở uống thuốc',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textBlack,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Tab "Lời mời tham gia": lời mời người khác gửi tới mình.
/// Chấp nhận sẽ mở [AcceptInvitationDialog] — sau đó còn phải chờ chủ nhóm duyệt.
class _IncomingInvitationsTab extends StatelessWidget {
  const _IncomingInvitationsTab();

  Future<void> _refreshIncomingInvitations(BuildContext context) async {
    await _dispatchAndAwaitFamilyRefresh(
      context,
      const FetchIncomingInvitations(),
    );
  }

  static final _inviteDateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      buildWhen: (previous, current) =>
          previous.incomingInvitations != current.incomingInvitations ||
          previous.status != current.status,
      builder: (context, state) {
        if (state.incomingInvitations.isEmpty &&
            state.status != FamilyStatus.loading) {
          return _RefreshableEmptyState(
            onRefresh: () => _refreshIncomingInvitations(context),
            icon: Icons.mail_outline,
            title: 'Không có lời mời nào',
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refreshIncomingInvitations(context),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: AppSize.p16,
              right: AppSize.p16,
              top: AppSize.p16,
              bottom:
                  AppSize.p16 +
                  MediaQuery.of(context).padding.bottom +
                  AppSize.bottomTabSafeInset,
            ),
            itemCount: state.incomingInvitations.length,
            itemBuilder: (context, index) {
              return _buildIncomingInvitationCard(
                context,
                state.incomingInvitations[index],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildIncomingInvitationCard(
    BuildContext context,
    IncomingInvitation invitation,
  ) {
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
                      '${invitation.memberCount} thành viên • ${_inviteDateFormat.format(invitation.sentAt)}',
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => _InvitationGroupDetailsDialog(
                    invitation: invitation,
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Xem chi tiết nhóm'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
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
                      barrierColor: Colors.black.withValues(
                        alpha: _kDialogBarrierAlpha,
                      ),
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

  void _showDeclineConfirmationDialog(
    BuildContext context,
    IncomingInvitation invitation,
  ) {
    ConfirmationDialog.showErrorConfirmation(
      context: context,
      title: 'Xác nhận từ chối',
      message:
          'Bạn có chắc chắn muốn từ chối lời mời tham gia nhóm "${invitation.groupName}"?',
      confirmText: 'Từ chối',
      onConfirm: () {
        context.read<FamilyBloc>().add(
          DeclineInvitation(groupId: invitation.groupId),
        );
      },
    );
  }
}

/// Xem trước nhóm trước khi phản hồi lời mời — mở từ nút "Xem chi tiết nhóm".
///
/// Danh sách thành viên lấy qua `getGroupMembersForInvitee`; người chưa là thành
/// viên chính thức thường bị BE từ chối, khi đó dialog hiện lời nhắc thay vì lỗi.
/// Chỉ để xem, không trả về giá trị nào.
class _InvitationGroupDetailsDialog extends StatefulWidget {
  final IncomingInvitation invitation;

  const _InvitationGroupDetailsDialog({
    required this.invitation,
  });

  @override
  State<_InvitationGroupDetailsDialog> createState() =>
      _InvitationGroupDetailsDialogState();
}

class _InvitationGroupDetailsDialogState
    extends State<_InvitationGroupDetailsDialog> {
  late final Future<List<FamilyMember>?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<List<FamilyMember>?> _loadDetails() async {
    try {
      final repo = context.read<FamilyRepository>();
      return await repo.getGroupMembersForInvitee(
        groupId: widget.invitation.groupId,
      );
    } catch (_) {
      return null;
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _memberSubtitle(FamilyMember member, String? ownerId) {
    if ((ownerId ?? '').isNotEmpty && member.userId == ownerId) {
      return 'Quản trị viên';
    }
    final relationship = (member.relationship ?? '').trim();
    if (relationship.isNotEmpty) {
      return relationship;
    }
    return 'Thành viên';
  }

  Widget _buildMemberTile(
    BuildContext context,
    FamilyMember member,
    String? ownerId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryLightGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(member.name),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                Text(
                  _memberSubtitle(member, ownerId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final invitation = widget.invitation;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSize.r24),
          clipBehavior: Clip.antiAlias,
          child: FutureBuilder<List<FamilyMember>?>(
            future: _detailsFuture,
            builder: (context, snapshot) {
              final loading =
                  snapshot.connectionState == ConnectionState.waiting;
              final members = snapshot.data ?? const <FamilyMember>[];
              final ownerId = widget.invitation.group?.ownerId ?? '';
              final canShowMembers = !loading && members.isNotEmpty;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDark.withValues(alpha: 0.14),
                          AppColors.primary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: const Border(
                        bottom: BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Chi tiết nhóm',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.textGrey,
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invitation.groupName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textBlack,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mời bởi: ${invitation.inviterName}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${invitation.memberCount} thành viên',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
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
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    _initials(invitation.inviterName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TẠO BỞI',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 0.6,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        invitation.inviterName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textBlack,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Người mời bạn tham gia nhóm',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Danh sách thành viên',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textBlack,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (!canShowMembers)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: const Text(
                                'Bạn chưa là thành viên chính thức nên chưa xem được danh sách thành viên. Hãy chấp nhận lời mời để xem đầy đủ chi tiết nhóm.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                  height: 1.35,
                                ),
                              ),
                            )
                          else
                            Column(
                              children: members
                                  .map(
                                    (member) => _buildMemberTile(
                                      context,
                                      member,
                                      ownerId,
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Đóng'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tab "Lời mời đã gửi": theo dõi trạng thái từng lời mời mình gửi đi.
/// `pendingOwnerApproval` nghĩa là người được mời đã đồng ý và đang chờ mình duyệt
/// — thao tác duyệt nằm ở màn chi tiết nhóm, không phải ở đây.
class _OutgoingInvitationsTab extends StatelessWidget {
  const _OutgoingInvitationsTab();

  Future<void> _refreshOutgoingInvitations(BuildContext context) async {
    await _dispatchAndAwaitFamilyRefresh(
      context,
      const FetchOutgoingInvitations(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      builder: (context, state) {
        // Hiện ngay trạng thái rỗng, không chờ loading — tránh nháy vòng xoay.
        if (state.outgoingInvitations.isEmpty &&
            state.status != FamilyStatus.loading) {
          return _RefreshableEmptyState(
            onRefresh: () => _refreshOutgoingInvitations(context),
            icon: Icons.send_outlined,
            title: 'Chưa có lời mời nào được gửi',
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refreshOutgoingInvitations(context),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: AppSize.p16,
              right: AppSize.p16,
              top: AppSize.p16,
              bottom:
                  AppSize.p16 +
                  MediaQuery.of(context).padding.bottom +
                  AppSize.bottomTabSafeInset,
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

  static final _outgoingDateFormat = DateFormat('dd/MM/yyyy');

  Widget _buildOutgoingInvitationCard(
    BuildContext context,
    OutgoingInvitation invitation,
  ) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (invitation.status) {
      case GroupMemberStatus.pending:
        statusText = 'Chờ người được mời';
        statusColor = Colors.orange;
        statusIcon = Icons.pending_outlined;
        break;
      case GroupMemberStatus.pendingOwnerApproval:
        // Invitee đã đồng ý, chờ chủ nhóm duyệt. [BE-REQ-03]
        statusText = 'Chờ chủ nhóm duyệt';
        statusColor = Colors.deepOrange;
        statusIcon = Icons.hourglass_top_rounded;
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
                      'Gửi ngày: ${_outgoingDateFormat.format(invitation.sentAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
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

/// Trạng thái rỗng vẫn kéo-để-làm-mới được: bọc trong vùng cuộn cao cố định để
/// `RefreshIndicator` có chỗ nhận cử chỉ vuốt dù không có nội dung nào.
class _RefreshableEmptyState extends StatelessWidget {
  const _RefreshableEmptyState({
    required this.onRefresh,
    required this.icon,
    required this.title,
  });

  final Future<void> Function() onRefresh;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * _kEmptyStateHeightFactor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: AppColors.textGrey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
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
                    color: AppColors.textGrey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
