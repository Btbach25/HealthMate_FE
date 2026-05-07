import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:flutter/material.dart';

/// Khung giờ trong ngày để gom reminder (theo giờ HH:mm).
enum MedicationSchedulePeriod {
  morning,
  noon,
  evening,
  night,
}

/// Một dòng trong lịch (một reminder trong một khung giờ).
class MedicationScheduleItem {
  final String medicationId;
  final String reminderId;
  final String name;
  final String dosage;
  final String time;
  final bool taken;
  final bool isOverdue;

  const MedicationScheduleItem({
    required this.medicationId,
    required this.reminderId,
    required this.name,
    required this.dosage,
    required this.time,
    required this.taken,
    required this.isOverdue,
  });
}

/// Style UI cho từng khung giờ (nhãn, icon, màu).
class MedicationPeriodBandStyle {
  final String label;
  final IconData icon;
  final Color color;
  final Color softBg;
  final String timeRange;

  const MedicationPeriodBandStyle({
    required this.label,
    required this.icon,
    required this.color,
    required this.softBg,
    required this.timeRange,
  });
}

/// Map dùng cho header từng section lịch.
const kMedicationPeriodBandStyles =
    <MedicationSchedulePeriod, MedicationPeriodBandStyle>{
  MedicationSchedulePeriod.morning: MedicationPeriodBandStyle(
    label: 'Sáng',
    icon: Icons.wb_twilight_rounded,
    color: AppColors.medicationScheduleMorning,
    softBg: AppColors.medicationScheduleMorningSoft,
    timeRange: '6:00 – 11:59',
  ),
  MedicationSchedulePeriod.noon: MedicationPeriodBandStyle(
    label: 'Trưa',
    icon: Icons.wb_sunny_rounded,
    color: AppColors.primary,
    softBg: AppColors.primaryContainer,
    timeRange: '12:00 – 16:59',
  ),
  MedicationSchedulePeriod.evening: MedicationPeriodBandStyle(
    label: 'Chiều',
    icon: Icons.filter_drama_rounded,
    color: AppColors.medicationScheduleEvening,
    softBg: AppColors.infoLight,
    timeRange: '17:00 – 20:59',
  ),
  MedicationSchedulePeriod.night: MedicationPeriodBandStyle(
    label: 'Tối',
    icon: Icons.nights_stay_rounded,
    color: AppColors.medicationScheduleNight,
    softBg: AppColors.medicationScheduleNightSoft,
    timeRange: '21:00 – 5:59',
  ),
};

/// Gom reminder theo khung giờ và sắp xếp trong từng khung.
Map<MedicationSchedulePeriod, List<MedicationScheduleItem>>
    buildMedicationDaySchedule(List<Medication> medications) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final currentTime =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  final schedule = <MedicationSchedulePeriod, List<MedicationScheduleItem>>{
    MedicationSchedulePeriod.morning: [],
    MedicationSchedulePeriod.noon: [],
    MedicationSchedulePeriod.evening: [],
    MedicationSchedulePeriod.night: [],
  };

  for (final med in medications) {
    if (!med.isActive) continue;
    final start = DateTime.tryParse(med.startDate);
    final end = med.endDate != null ? DateTime.tryParse(med.endDate!) : null;
    if (start != null) {
      final startDay = DateTime(start.year, start.month, start.day);
      if (today.isBefore(startDay)) continue;
    }
    if (end != null) {
      final endDay = DateTime(end.year, end.month, end.day);
      if (today.isAfter(endDay)) continue;
    }
    for (final reminder in med.reminders) {
      if (!reminder.isEnabled) continue;

      final isTaken = reminder.isTakenToday;
      final isOverdue =
          !isTaken && reminder.time.compareTo(currentTime) < 0;

      final hour = int.tryParse(reminder.time.split(':').first) ?? 0;
      final MedicationSchedulePeriod period;
      if (hour >= 6 && hour < 12) {
        period = MedicationSchedulePeriod.morning;
      } else if (hour >= 12 && hour < 17) {
        period = MedicationSchedulePeriod.noon;
      } else if (hour >= 17 && hour < 21) {
        period = MedicationSchedulePeriod.evening;
      } else {
        period = MedicationSchedulePeriod.night;
      }

      schedule[period]!.add(
        MedicationScheduleItem(
          medicationId: med.id,
          reminderId: reminder.id,
          name: med.name,
          dosage: med.dosage,
          time: reminder.time,
          taken: isTaken,
          isOverdue: isOverdue,
        ),
      );
    }
  }

  for (final list in schedule.values) {
    list.sort((a, b) => a.time.compareTo(b.time));
  }
  return schedule;
}
