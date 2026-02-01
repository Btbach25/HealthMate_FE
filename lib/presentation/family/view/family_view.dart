import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/widgets/loading_widget.dart';
import 'package:fe/core/widgets/error_widget.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/widgets/create_group_dialog.dart';
import 'package:fe/presentation/family/widgets/family_app_bar.dart';
import 'package:fe/presentation/family/widgets/family_group_card.dart';
import 'package:fe/presentation/family/widgets/family_summary_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FamilyView extends StatelessWidget {
  const FamilyView({super.key});

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
                context.read<FamilyBloc>().add(const FetchFamilyGroups());
              },
            );
          }

          // Show loaded state if status is loaded or groupDetailsLoaded (when returning from group details)
          if (state.status == FamilyStatus.loaded ||
              state.status == FamilyStatus.creatingGroup ||
              state.status == FamilyStatus.groupCreated ||
              state.status == FamilyStatus.groupDetailsLoaded ||
              state.status == FamilyStatus.memberInvited ||
              state.status == FamilyStatus.memberRemoved ||
              state.status == FamilyStatus.groupUpdated ||
              state.status == FamilyStatus.ownershipTransferred ||
              state.status == FamilyStatus.groupLeft ||
              state.status == FamilyStatus.invitationsLoaded ||
              state.status == FamilyStatus.invitationAccepted ||
              state.status == FamilyStatus.invitationDeclined) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSize.maxWidth),
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<FamilyBloc>().add(const FetchFamilyGroups());
                    // Wait for the state to update
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSize.p20),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FamilyAppBar(),
                      const SizedBox(height: AppSize.spacing32),
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
                        pendingInvitations: state.summary.pendingInvitations,
                      ),
                      const SizedBox(height: 32),

                      // Family groups list
                      if (state.summary.groups.isNotEmpty) ...[
                        Text(
                          'Nhóm của bạn',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSize.spacing20),
                        ...state.summary.groups.map((group) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSize.spacing16),
                              child: FamilyGroupCard(group: group),
                            )),
                        const SizedBox(height: AppSize.spacing8),
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
          }

          return const Center(child: Text('Trạng thái không xác định'));
        },
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


