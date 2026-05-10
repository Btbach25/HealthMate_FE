import 'package:fe/core/constants/app_size.dart';
import 'package:fe/data/enums/group_member_status.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/widgets/loading_widget.dart';
import 'package:fe/core/widgets/error_widget.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/widgets/create_group_dialog.dart';
import 'package:fe/presentation/family/widgets/family_group_card.dart';
import 'package:fe/presentation/family/widgets/family_summary_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FamilyView extends StatelessWidget {
  const FamilyView({super.key});

  static const double _contentMaxWidth = 800;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<FamilyBloc, FamilyState>(
        builder: (context, state) {
          if (state.status == FamilyStatus.initial ||
              state.status == FamilyStatus.loading) {
            return const LoadingWidget(
              message: 'Đang tải danh sách nhóm...',
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
                  context.read<FamilyBloc>().add(const FetchFamilyGroups());
                }
              },
            );
          }

          return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: RefreshIndicator(
                  onRefresh: () async {
                    final bloc = context.read<FamilyBloc>();
                    bloc.add(const FetchFamilyGroups());
                    try {
                      await bloc.stream
                          .firstWhere((s) => s.status != FamilyStatus.loading)
                          .timeout(const Duration(seconds: 45));
                    } catch (_) {}
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSize.p20),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gia đình',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Quản lý nhóm và quyền chia sẻ trong gia đình',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      const SizedBox(height: AppSize.spacing24),
                      // Header section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chọn nhóm gia đình',
                                  style: AppTextStyles.h2,
                                ),
                                const SizedBox(height: AppSize.spacing8),
                                Text(
                                  'Chọn nhóm để xem thông tin sức khỏe của các thành viên',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSize.spacing16),
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryLightGradient,
                              borderRadius: BorderRadius.circular(AppSize.r12),
                              boxShadow: AppColors.buttonShadow,
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                context.push('/family/manage');
                              },
                              icon: const Icon(
                                Icons.settings_outlined,
                                size: AppSize.icon20,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Quản lý',
                                style: AppTextStyles.buttonMedium,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSize.p20,
                                  vertical: AppSize.p12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSize.spacing32),

                      // Summary cards
                      FamilySummaryCards(
                        groupsJoined: state.summary.groupsJoined,
                        pendingInvitations: _totalPendingInvitations(state),
                      ),
                      const SizedBox(height: 20),
                      const _FamilyPurposeBanner(),
                      const SizedBox(height: 28),

                      // Family groups list
                      if (state.summary.groups.isNotEmpty) ...[
                        Text(
                          'Nhóm của bạn',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSize.spacing20),
                        ...state.summary.groups.map((group) {
                              final currentUserId = context.read<AuthBloc>().state.user.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSize.spacing16),
                                child: FamilyGroupCard(
                                  group: group,
                                  currentUserId: currentUserId.isEmpty ? null : currentUserId,
                                ),
                              );
                            }),
                        const SizedBox(height: AppSize.spacing8),
                      ],

                      if (state.summary.groups.isEmpty) ...[
                        const _FamilyEmptyGroupsHint(),
                        const SizedBox(height: AppSize.spacing24),
                      ],

                      // Create new group card
                      const _CreateGroupCard(),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                    ],
                  ),
                  ),
                ),
              ),
            );
        },
      ),
    );
  }
}

/// Giá trị nhân văn + minh bạch mục đích (không thay thế dịch vụ y tế).
class _FamilyPurposeBanner extends StatelessWidget {
  const _FamilyPurposeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSize.p16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppSize.r16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            color: AppColors.primary,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chăm sóc sức khỏe cùng người thân',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nhóm gia đình giúp phối hợp theo dõi, hỗ trợ người cao tuổi và người bệnh mạn tính — minh bạch và tôn trọng quyền riêng tư.',
                  style: AppTextStyles.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyEmptyGroupsHint extends StatelessWidget {
  const _FamilyEmptyGroupsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSize.p16,
        vertical: AppSize.p20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSize.r16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.groups_2_outlined,
            color: AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bắt đầu bằng một nhóm nhỏ',
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tạo nhóm để mời người nhà, cùng xem chỉ số và hỗ trợ nhau trong chăm sóc hằng ngày.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textGrey,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateGroupCard extends StatelessWidget {
  const _CreateGroupCard();

  void _openCreateGroupDialog(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCreateGroupDialog(context),
      child: Container(
        padding: const EdgeInsets.all(AppSize.p24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha:0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppColors.buttonShadow,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: AppSize.icon32,
              ),
            ),
            const SizedBox(height: AppSize.spacing20),
            const Text(
              'Tạo nhóm mới',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppSize.spacing8),
            Text(
              'Tạo nhóm để chia sẻ dữ liệu sức khỏe với gia đình',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: AppSize.spacing20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSize.r12),
                boxShadow: AppColors.buttonShadow,
              ),
              child: ElevatedButton(
                onPressed: () => _openCreateGroupDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSize.p16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSize.r12),
                  ),
                ),
                child: const Text(
                  'Tạo nhóm mới',
                  style: AppTextStyles.buttonLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lời mời đến (cần phản hồi) + lời mời đi cần action (pending hoặc pendingOwnerApproval).
/// [BE-REQ-03] pendingOwnerApproval được tính vào badge vì chủ nhóm cần duyệt.
int _totalPendingInvitations(FamilyState state) {
  final outgoingActive = state.outgoingInvitations
      .where((o) =>
          o.status == GroupMemberStatus.pending ||
          o.status == GroupMemberStatus.pendingOwnerApproval)
      .length;
  return state.incomingInvitations.length + outgoingActive;
}

