import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/widgets/card_with_accent_bar.dart';
import 'package:fe/presentation/medications/view/medication_day_schedule.dart';
import 'package:fe/presentation/medications/widgets/medication_item_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Thẻ "Lịch hôm nay" + progress + từng khung giờ hoặc empty state.
class MedicationScheduleCard extends StatelessWidget {
  final Map<MedicationSchedulePeriod, List<MedicationScheduleItem>> schedule;
  final int completedCount;
  final int totalCount;
  final VoidCallback onAddMedication;
  final void Function(String medicationId, String reminderId) onTake;

  const MedicationScheduleCard({
    super.key,
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
              MedicationScheduleEmpty(onAdd: onAddMedication),
            ] else ...[
              const SizedBox(height: 12),
              ...MedicationSchedulePeriod.values.map((period) {
                final config = kMedicationPeriodBandStyles[period]!;
                final items = schedule[period]!;
                return MedicationPeriodSection(
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

/// Trạng thái rỗng của [MedicationScheduleCard]: hiện khi hôm nay không có lần
/// uống nào. Bắt buộc [onAdd] vì cả khối là lời mời thêm thuốc.
class MedicationScheduleEmpty extends StatelessWidget {
  final VoidCallback onAdd;

  const MedicationScheduleEmpty({super.key, required this.onAdd});

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

/// Một khung giờ trong lịch hôm nay (Sáng / Trưa / Chiều / Tối): dải tiêu đề
/// có màu riêng + danh sách [MedicationItemCard] bên dưới.
///
/// Chỉ dựng bởi [MedicationScheduleCard]; màu và nhãn lấy từ
/// `medicationPeriodBandStyles`, không truyền tay.
class MedicationPeriodSection extends StatelessWidget {
  final MedicationPeriodBandStyle config;
  final List<MedicationScheduleItem> items;
  final void Function(String medicationId, String reminderId) onTake;

  const MedicationPeriodSection({
    super.key,
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
class MedicationPurposeBanner extends StatelessWidget {
  const MedicationPurposeBanner({super.key});

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
