import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/presentation/medications/bloc/medication_bloc.dart';
import 'package:fe/presentation/medications/widgets/add_medication_sheet.dart';
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
  final String timeRange;

  const _PeriodConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.timeRange,
  });
}

final _periodConfigs = <_Period, _PeriodConfig>{
  _Period.morning: const _PeriodConfig(
    label: 'Sáng',
    icon: Icons.wb_twilight,
    color: Color(0xFFF57C00),
    timeRange: '6:00 - 11:59',
  ),
  _Period.noon: const _PeriodConfig(
    label: 'Trưa',
    icon: Icons.wb_sunny,
    color: Color(0xFFFFA000),
    timeRange: '12:00 - 16:59',
  ),
  _Period.evening: const _PeriodConfig(
    label: 'Chiều',
    icon: Icons.wb_twilight,
    color: Color(0xFF1976D2),
    timeRange: '17:00 - 20:59',
  ),
  _Period.night: const _PeriodConfig(
    label: 'Tối',
    icon: Icons.bedtime_outlined,
    color: Color(0xFF7B1FA2),
    timeRange: '21:00 - 5:59',
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
      body: BlocBuilder<MedicationBloc, MedicationState>(
        builder: (context, state) {
          if (state.status == MedicationStatus.initial ||
              state.status == MedicationStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == MedicationStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage ?? 'Đã có lỗi xảy ra',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<MedicationBloc>()
                        .add(const FetchMedications()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
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
            backgroundColor: AppColors.inputBackground,
            strokeWidth: 2.5,
            displacement: 64,
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
                  padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                          onAdd: () => _showAddSheet(context)),
                      const SizedBox(height: 16),
                      _SummaryRow(
                          total: total, taken: taken, missed: missed),
                      const SizedBox(height: 12),
                      _ScanButton(),
                      const SizedBox(height: 16),
                      _ScheduleCard(
                        schedule: schedule,
                        completedCount: taken,
                        totalCount: total,
                        onTake: (medId, remId) =>
                            context.read<MedicationBloc>().add(
                                  TakeMedication(
                                    medicationId: medId,
                                    reminderId: remId,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 80),
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

  void _showAddSheet(BuildContext context) {
    final bloc = context.read<MedicationBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const AddMedicationSheet(),
      ),
    );
  }
}

// ─── Private sub-widgets ───────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Quản lý thuốc', style: AppTextStyles.h4),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Thêm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle: AppTextStyles.labelMedium
                .copyWith(color: Colors.white),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int total;
  final int taken;
  final int missed;
  const _SummaryRow(
      {required this.total, required this.taken, required this.missed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatBox(value: total, label: 'Tổng thuốc')),
        const SizedBox(width: 10),
        Expanded(
            child: _StatBox(
                value: taken,
                label: 'Đã uống',
                valueColor: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
            child: _StatBox(
                value: missed,
                label: 'Bị lỡ',
                valueColor: missed > 0 ? AppColors.error : AppColors.textBlack)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final int value;
  final String label;
  final Color? valueColor;

  const _StatBox({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTextStyles.h3.copyWith(
              color: valueColor ?? AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tính năng quét đơn thuốc đang phát triển'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt_outlined,
            size: 20, color: AppColors.textBlack),
        label: const Text('Quét đơn thuốc',
            style: TextStyle(color: AppColors.textBlack)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.surface,
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<_Period, List<_ScheduleItem>> schedule;
  final int completedCount;
  final int totalCount;
  final void Function(String medicationId, String reminderId) onTake;

  const _ScheduleCard({
    required this.schedule,
    required this.completedCount,
    required this.totalCount,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'vi_VN')
        .format(DateTime.now());
    final allEmpty = schedule.values.every((list) => list.isEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: AppColors.textBlack),
                        const SizedBox(width: 8),
                        Text('Lịch uống thuốc hôm nay',
                            style: AppTextStyles.labelLarge),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: completedCount == totalCount && totalCount > 0
                      ? AppColors.primaryContainer
                      : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: completedCount == totalCount && totalCount > 0
                        ? AppColors.primary
                        : AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (allEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.medication_outlined,
                      size: 48, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text('Không có thuốc nào hôm nay',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textGrey)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ] else ...[
            const SizedBox(height: 20),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period header
          Row(
            children: [
              Icon(config.icon, size: 20, color: config.color),
              const SizedBox(width: 6),
              Text(config.label,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: config.color)),
              const SizedBox(width: 6),
              Text('(${config.timeRange})',
                  style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 10),
          // Medication items
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.cardBorder,
                    style: BorderStyle.solid,
                    width: 1),
              ),
              child: Text(
                'Không có thuốc nào trong buổi ${config.label.toLowerCase()}',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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
