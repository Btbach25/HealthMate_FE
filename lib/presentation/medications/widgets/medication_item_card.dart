import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Thẻ một lần uống trong lịch — tap cả thẻ để đánh dấu đã uống.
class MedicationItemCard extends StatelessWidget {
  final String name;
  final String dosage;
  final String time;
  final bool taken;
  final bool isOverdue;
  final VoidCallback onTap;

  const MedicationItemCard({
    super.key,
    required this.name,
    required this.dosage,
    required this.time,
    required this.taken,
    required this.isOverdue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = taken
        ? AppColors.primary
        : isOverdue
            ? AppColors.error
            : AppColors.textGrey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: taken ? AppColors.primaryContainer : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: taken
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : isOverdue
                      ? AppColors.error.withValues(alpha: 0.35)
                      : AppColors.cardBorder,
              width: 1,
            ),
            boxShadow: taken
                ? null
                : [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(13),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: taken
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.medication_rounded,
                            color: taken
                                ? AppColors.primary
                                : AppColors.textGrey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: AppTextStyles.labelMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dosage,
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                time,
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              taken
                                  ? 'Đã uống'
                                  : isOverdue
                                      ? 'Quá giờ'
                                      : 'Chờ uống',
                              style: AppTextStyles.caption.copyWith(
                                color: taken
                                    ? AppColors.primary
                                    : isOverdue
                                        ? AppColors.error
                                        : AppColors.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Semantics(
                          label: taken
                              ? 'Bỏ đánh dấu đã uống'
                              : 'Đánh dấu đã uống',
                          button: true,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: taken
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: taken
                                    ? AppColors.primary
                                    : AppColors.cardBorder,
                                width: 2,
                              ),
                            ),
                            child: taken
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  )
                                : Icon(
                                    Icons.circle_outlined,
                                    color: AppColors.textLight,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
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
