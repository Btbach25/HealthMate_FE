import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/models/health/medication_progress.dart';
import 'package:flutter/material.dart';

/// Thẻ tóm tắt tiến độ uống thuốc trong ngày: tổng số lượt, đã uống, còn lại và
/// một thanh tiến độ.
///
/// [progress] bắt buộc. Phía gọi phải tự kiểm tra null trước khi dựng widget —
/// [HomeView] chỉ render thẻ này khi `homeData.medicationProgress != null`.
///
/// Tái sử dụng được ở màn hình quản lý thuốc: widget thuần trình bày, không đọc bloc
/// và tự xử lý trường hợp `total == 0` (chia cho 0) nên nhận dữ liệu rỗng vẫn an toàn.
class MedicationCard extends StatelessWidget {
  final MedicationProgress progress;
  const MedicationCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final double percent = (progress.total > 0)
        ? progress.completed / progress.total
        : 0.0;
    final int remaining = progress.total - progress.completed;
    final bool done = remaining == 0 && progress.total > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(AppIcons.medication, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Thuốc hôm nay',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: done ? AppColors.successLight : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  done ? 'Hoàn thành' : 'Còn $remaining lần',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: done ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _StatBox(label: 'Lượt uống', value: '${progress.total}', color: AppColors.primary)),
                const VerticalDivider(width: 16, thickness: 0.8, color: AppColors.cardBorder),
                Expanded(child: _StatBox(label: 'Đã uống', value: '${progress.completed}', color: AppColors.success)),
                const VerticalDivider(width: 16, thickness: 0.8, color: AppColors.cardBorder),
                Expanded(child: _StatBox(label: 'Còn lại', value: '$remaining', color: remaining > 0 ? AppColors.warning : AppColors.textGrey)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.inputBackground,
              color: done ? AppColors.success : AppColors.primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Một ô số liệu trong hàng ba cột của [MedicationCard].
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}