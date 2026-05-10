import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/widgets/app_stat_tile.dart';
import 'package:fe/core/widgets/error_widget.dart';
import 'package:fe/core/widgets/feature_highlight_card.dart';
import 'package:fe/core/widgets/hero_action_banner.dart';
import 'package:fe/core/widgets/loading_widget.dart';
import 'package:fe/presentation/medications/bloc/medication_bloc.dart';
import 'package:fe/presentation/medications/view/medication_day_schedule.dart';
import 'package:fe/presentation/medications/view/medication_schedule_widgets.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/presentation/medications/widgets/add_medication_dialog.dart';
import 'package:fe/presentation/medications/widgets/manage_medications_dialog.dart';
import 'package:fe/presentation/medications/widgets/medication_share_dialog.dart';
import 'package:fe/presentation/medications/widgets/prescription_scan_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicationView extends StatelessWidget {
  const MedicationView({super.key});

  static const String _manageButtonLabel = 'Chỉnh sửa';
  static const String _shareButtonLabel = 'Chia sẻ';
  static const String _addButtonLabel = 'Thêm';
  static const double _contentMaxWidth = 800;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<MedicationBloc, MedicationState>(
        listenWhen: (previous, current) =>
            current.feedbackMessage != null &&
            (previous.feedbackMessage != current.feedbackMessage ||
                previous.feedbackIsError != current.feedbackIsError),
        listener: (context, state) {
          final msg = state.feedbackMessage;
          if (msg == null || !context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: state.feedbackIsError
                  ? AppColors.error
                  : AppColors.primary,
            ),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.read<MedicationBloc>().add(const ClearMedicationFeedback());
          });
        },
        child: BlocBuilder<MedicationBloc, MedicationState>(
          builder: (context, state) {
            if (state.status == MedicationStatus.initial ||
                state.status == MedicationStatus.loading) {
              return const Center(
                child: LoadingWidget(
                  message: 'Đang tải lịch thuốc',
                  subtitle: 'Vui lòng đợi trong giây lát',
                  progressInElevatedCircle: true,
                ),
              );
            }

            if (state.status == MedicationStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ErrorDisplayWidget(
                    title: 'Không tải được dữ liệu',
                    message: state.errorMessage ?? 'Đã có lỗi xảy ra',
                    wrapInCard: true,
                    icon: Icons.cloud_off_rounded,
                    onRetry: () => context
                        .read<MedicationBloc>()
                        .add(const FetchMedications()),
                  ),
                ),
              );
            }

            final schedule = buildMedicationDaySchedule(state.medications);
            final allItems =
                schedule.values.expand((list) => list).toList();
            final total = allItems.length;
            final taken = allItems.where((i) => i.taken).length;
            final missed =
                allItems.where((i) => i.isOverdue && !i.taken).length;

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              strokeWidth: 2.5,
              displacement: 72,
              edgeOffset: 8,
              onRefresh: () async {
                final bloc = context.read<MedicationBloc>();
                bloc.add(const FetchMedications());
                try {
                  await bloc.stream
                      .firstWhere(
                        (s) => s.status != MedicationStatus.loading,
                      )
                      .timeout(const Duration(seconds: 45));
                } catch (_) {
                  // Đóng indicator dù stream không phát (timeout / lỗi mạng).
                }
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompactPhone = constraints.maxWidth < 390;
                        const statSpacing = 10.0;
                        const minStatTileWidth = 100.0;
                        var statsPerRow =
                            ((constraints.maxWidth + statSpacing) /
                                    (minStatTileWidth + statSpacing))
                                .floor()
                                .clamp(1, 3);
                        if (constraints.maxWidth >= 700) {
                          statsPerRow = 3;
                        } else if (constraints.maxWidth >= 330 &&
                            statsPerRow < 2) {
                          // Tránh rơi về 1 cột trên đa số điện thoại.
                          statsPerRow = 2;
                        }
                        final statTileWidth = (constraints.maxWidth -
                                (statSpacing * (statsPerRow - 1))) /
                            statsPerRow;
                        final actionAlignment = constraints.maxWidth < 520
                            ? WrapAlignment.start
                            : WrapAlignment.end;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        const MedicationPurposeBanner(),
                        const SizedBox(height: 12),
                        HeroActionBanner(
                          title: 'Thuốc & lịch uống',
                          subtitle:
                              'Theo dõi nhắc nhở, đánh dấu đã uống và quét đơn nhanh chóng.',
                          action: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: actionAlignment,
                            children: [
                              OutlinedButton.icon(
                                onPressed: state.medications.isEmpty
                                    ? null
                                    : () => _showManageMedicationsDialog(context),
                                icon: Icon(
                                  Icons.edit_rounded,
                                  size: isCompactPhone ? 18 : 20,
                                ),
                                label: const Text(_manageButtonLabel),
                                style: _outlinedHeroActionStyle(isCompactPhone),
                              ),
                              OutlinedButton.icon(
                                onPressed: state.medications.isEmpty
                                    ? null
                                    : () => _showShareMedicationDialog(context, state.medications),
                                icon: Icon(
                                  Icons.group_add_outlined,
                                  size: isCompactPhone ? 18 : 20,
                                ),
                                label: const Text(_shareButtonLabel),
                                style: _outlinedHeroActionStyle(isCompactPhone),
                              ),
                              FilledButton.icon(
                                onPressed: () =>
                                    _showAddMedicationDialog(context),
                                icon: Icon(
                                  Icons.add_rounded,
                                  size: isCompactPhone ? 20 : 22,
                                ),
                                label: const Text(_addButtonLabel),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.surface,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompactPhone ? 12 : 16,
                                    vertical: 12,
                                  ),
                                  visualDensity: isCompactPhone
                                      ? const VisualDensity(
                                          horizontal: -2,
                                          vertical: 0,
                                        )
                                      : VisualDensity.standard,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: statSpacing,
                          runSpacing: statSpacing,
                          children: [
                            _buildStatTile(
                              width: statTileWidth,
                              icon: Icons.event_note_rounded,
                              iconBg: AppColors.inputBackground,
                              iconColor: AppColors.textSecondary,
                              value: total,
                              label: 'Lượt uống',
                              valueColor: AppColors.textBlack,
                            ),
                            _buildStatTile(
                              width: statTileWidth,
                              icon: Icons.task_alt_rounded,
                              iconBg: AppColors.primaryContainer,
                              iconColor: AppColors.primary,
                              value: taken,
                              label: 'Đã uống',
                              valueColor: AppColors.primary,
                            ),
                            _buildStatTile(
                              width: statTileWidth,
                              icon: Icons.schedule_rounded,
                              iconBg: missed > 0
                                  ? AppColors.errorLight
                                  : AppColors.inputBackground,
                              iconColor: missed > 0
                                  ? AppColors.error
                                  : AppColors.textGrey,
                              value: missed,
                              label: 'Cần chú ý',
                              valueColor: missed > 0
                                  ? AppColors.error
                                  : AppColors.textBlack,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FeatureHighlightCard(
                          leadingIcon: Icons.document_scanner_rounded,
                          title: 'Quét đơn thuốc',
                          subtitle:
                              'Chụp hoặc chọn ảnh — gợi ý tên & liều tự động',
                          showTrailingChevron: true,
                          onTap: () async {
                            await showPrescriptionScanDialog(context);
                            if (!context.mounted) return;
                            context
                                .read<MedicationBloc>()
                                .add(const FetchMedications());
                          },
                        ),
                        const SizedBox(height: 20),
                        MedicationScheduleCard(
                          schedule: schedule,
                          completedCount: taken,
                          totalCount: total,
                          onAddMedication: () =>
                              _showAddMedicationDialog(context),
                          onTake: (medId, remId) =>
                              context.read<MedicationBloc>().add(
                                    TakeMedication(
                                      medicationId: medId,
                                      reminderId: remId,
                                    ),
                                  ),
                        ),
                      ],
                    );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    final bloc = context.read<MedicationBloc>();
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const AddMedicationDialog(),
      ),
    );
  }

  Future<void> _showShareMedicationDialog(
    BuildContext context,
    List<Medication> medications,
  ) async {
    if (medications.isEmpty) return;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (_) => MedicationShareDialog(medications: medications),
    );
  }

  void _showManageMedicationsDialog(BuildContext context) {
    final bloc = context.read<MedicationBloc>();
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const ManageMedicationsDialog(),
      ),
    );
  }

  Widget _buildStatTile({
    required double width,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required int value,
    required String label,
    required Color valueColor,
  }) {
    return SizedBox(
      width: width,
      child: AppStatTile(
        icon: icon,
        iconBg: iconBg,
        iconColor: iconColor,
        value: value,
        label: label,
        valueColor: valueColor,
      ),
    );
  }

  ButtonStyle _outlinedHeroActionStyle(bool isCompactPhone) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      padding: EdgeInsets.symmetric(
        horizontal: isCompactPhone ? 10 : 14,
        vertical: 12,
      ),
      visualDensity: isCompactPhone
          ? const VisualDensity(
              horizontal: -2,
              vertical: 0,
            )
          : VisualDensity.standard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
