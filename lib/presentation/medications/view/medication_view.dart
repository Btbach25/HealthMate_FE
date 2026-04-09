import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/widgets/app_stat_tile.dart';
import 'package:fe/core/widgets/card_with_accent_bar.dart';
import 'package:fe/core/widgets/error_widget.dart';
import 'package:fe/core/widgets/feature_highlight_card.dart';
import 'package:fe/core/widgets/hero_action_banner.dart';
import 'package:fe/core/widgets/loading_widget.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/presentation/medications/bloc/medication_bloc.dart';
import 'package:fe/presentation/medications/widgets/add_medication_dialog.dart';
import 'package:fe/presentation/medications/widgets/manage_medications_dialog.dart';
import 'package:fe/presentation/medications/widgets/prescription_scan_dialog.dart';
import 'package:fe/presentation/medications/widgets/medication_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// ─── Schedule data types (file-private) ───────────────────────────────────────

enum _Period { morning, noon, evening, night }

class _ScheduleItem {
  final String medicationId;
  final String reminderId;
  final String name;
  final String dosage;
  final String time;
  final bool taken;
  final bool isOverdue;

  const _ScheduleItem({
    required this.medicationId,
    required this.reminderId,
    required this.name,
    required this.dosage,
    required this.time,
    required this.taken,
    required this.isOverdue,
  });
}

class _PeriodConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color softBg;
  final String timeRange;

  const _PeriodConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.softBg,
    required this.timeRange,
  });
}

final _periodConfigs = <_Period, _PeriodConfig>{
  _Period.morning: _PeriodConfig(
    label: 'Sáng',
    icon: Icons.wb_twilight_rounded,
    color: AppColors.medicationScheduleMorning,
    softBg: AppColors.medicationScheduleMorningSoft,
    timeRange: '6:00 – 11:59',
  ),
  _Period.noon: _PeriodConfig(
    label: 'Trưa',
    icon: Icons.wb_sunny_rounded,
    color: AppColors.primary,
    softBg: AppColors.primaryContainer,
    timeRange: '12:00 – 16:59',
  ),
  _Period.evening: _PeriodConfig(
    label: 'Chiều',
    icon: Icons.filter_drama_rounded,
    color: AppColors.medicationScheduleEvening,
    softBg: AppColors.infoLight,
    timeRange: '17:00 – 20:59',
  ),
  _Period.night: _PeriodConfig(
    label: 'Tối',
    icon: Icons.nights_stay_rounded,
    color: AppColors.medicationScheduleNight,
    softBg: AppColors.medicationScheduleNightSoft,
    timeRange: '21:00 – 5:59',
  ),
};

// ─── Schedule computation ──────────────────────────────────────────────────────

Map<_Period, List<_ScheduleItem>> _buildSchedule(
    List<Medication> medications) {
  final now = DateTime.now();
  final currentTime =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  final schedule = <_Period, List<_ScheduleItem>>{
    _Period.morning: [],
    _Period.noon: [],
    _Period.evening: [],
    _Period.night: [],
  };

  for (final med in medications) {
    if (!med.isActive) continue;
    for (final reminder in med.reminders) {
      if (!reminder.isEnabled) continue;

      final isTaken = reminder.isTakenToday;
      final isOverdue =
          !isTaken && reminder.time.compareTo(currentTime) < 0;

      final hour = int.tryParse(reminder.time.split(':').first) ?? 0;
      final _Period period;
      if (hour >= 6 && hour < 12) {
        period = _Period.morning;
      } else if (hour >= 12 && hour < 17) {
        period = _Period.noon;
      } else if (hour >= 17 && hour < 21) {
        period = _Period.evening;
      } else {
        period = _Period.night;
      }

      schedule[period]!.add(_ScheduleItem(
        medicationId: med.id,
        reminderId: reminder.id,
        name: med.name,
        dosage: med.dosage,
        time: reminder.time,
        taken: isTaken,
        isOverdue: isOverdue,
      ));
    }
  }

  for (final list in schedule.values) {
    list.sort((a, b) => a.time.compareTo(b.time));
  }
  return schedule;
}

// ─── Main View ─────────────────────────────────────────────────────────────────

class MedicationView extends StatelessWidget {
  const MedicationView({super.key});

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

          final schedule = _buildSchedule(state.medications);
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
              await bloc.stream.firstWhere(
                  (s) => s.status != MedicationStatus.loading);
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _MedicationPurposeBanner(),
                      const SizedBox(height: 12),
                      HeroActionBanner(
                        title: 'Thuốc & lịch uống',
                        subtitle:
                            'Theo dõi nhắc nhở, đánh dấu đã uống và quét đơn nhanh chóng.',
                        action: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: state.medications.isEmpty
                                  ? null
                                  : () =>
                                      _showManageMedicationsDialog(context),
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              label: const Text('Chỉnh sửa'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () =>
                                  _showAddMedicationDialog(context),
                              icon: const Icon(Icons.add_rounded, size: 22),
                              label: const Text('Thêm'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.surface,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppStatTile(
                              icon: Icons.event_note_rounded,
                              iconBg: AppColors.inputBackground,
                              iconColor: AppColors.textSecondary,
                              value: total,
                              label: 'Lượt uống',
                              valueColor: AppColors.textBlack,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppStatTile(
                              icon: Icons.task_alt_rounded,
                              iconBg: AppColors.primaryContainer,
                              iconColor: AppColors.primary,
                              value: taken,
                              label: 'Đã uống',
                              valueColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppStatTile(
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
                      _ScheduleCard(
                        schedule: schedule,
                        completedCount: taken,
                        totalCount: total,
                        onAddMedication: () => _showAddMedicationDialog(context),
                        onTake: (medId, remId) =>
                            context.read<MedicationBloc>().add(
                                  TakeMedication(
                                    medicationId: medId,
                                    reminderId: remId,
                                  ),
                                ),
                      ),
                    ],
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
}

// ─── Schedule card ─────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final Map<_Period, List<_ScheduleItem>> schedule;
  final int completedCount;
  final int totalCount;
  final VoidCallback onAddMedication;
  final void Function(String medicationId, String reminderId) onTake;

  const _ScheduleCard({
    required this.schedule,
    required this.completedCount,
    required this.totalCount,
    required this.onAddMedication,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'vi_VN')
        .format(DateTime.now());
    final allEmpty = schedule.values.every((list) => list.isEmpty);
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final allDone = totalCount > 0 && completedCount == totalCount;

    return CardWithAccentBar(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Lịch hôm nay',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontSize: 17,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: allDone
                                  ? AppColors.successLight
                                  : AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              '$completedCount / $totalCount',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: allDone
                                    ? AppColors.success
                                    : AppColors.textGrey,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (totalCount > 0) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.inputBackground,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                allDone
                    ? 'Hoàn thành tất cả lịch trong ngày — tuyệt vời!'
                    : 'Còn ${totalCount - completedCount} lần uống trong ngày',
                style: AppTextStyles.caption,
              ),
            ],
            if (allEmpty) ...[
              const SizedBox(height: 16),
              _ScheduleEmpty(onAdd: onAddMedication),
            ] else ...[
              const SizedBox(height: 12),
              ..._Period.values.map((period) {
                final config = _periodConfigs[period]!;
                final items = schedule[period]!;
                return _PeriodSection(
                  config: config,
                  items: items,
                  onTake: onTake,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleEmpty extends StatelessWidget {
  final VoidCallback onAdd;

  const _ScheduleEmpty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication_liquid_rounded,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa có lịch uống hôm nay',
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Thêm thuốc để nhận nhắc theo giờ, hoặc quét đơn để nhập nhanh.',
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
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Thêm thuốc'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodSection extends StatelessWidget {
  final _PeriodConfig config;
  final List<_ScheduleItem> items;
  final void Function(String medicationId, String reminderId) onTake;

  const _PeriodSection({
    required this.config,
    required this.items,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: config.softBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(config.icon, size: 18, color: config.color),
                    const SizedBox(width: 6),
                    Text(
                      config.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: config.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      config.timeRange,
                      style: AppTextStyles.caption.copyWith(
                        color: config.color.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '${items.length}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cardBorder,
                ),
              ),
              child: Text(
                'Không có thuốc trong khung ${config.label.toLowerCase()}',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MedicationItemCard(
                    name: item.name,
                    dosage: item.dosage,
                    time: item.time,
                    taken: item.taken,
                    isOverdue: item.isOverdue,
                    onTap: () => onTake(item.medicationId, item.reminderId),
                  ),
                )),
        ],
      ),
    );
  }
}

/// Nhắc nhở nhân văn + giới hạn trách nhiệm (ứng dụng hỗ trợ, không tư vấn y khoa).
class _MedicationPurposeBanner extends StatelessWidget {
  const _MedicationPurposeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.favorite_outline_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hỗ trợ tuân thủ điều trị tại nhà',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lịch và nhắc nhở mang tính hỗ trợ; không thay thế chỉ định của bác sĩ hay dược sĩ.',
                  style: AppTextStyles.caption.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
