// lib/presentation/home/widgets/stat_card.dart
import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final String title;
  final String value;
  final String? unit;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    this.iconBgColor,
    required this.title,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadowList,
      ),
      // Dùng LayoutBuilder để biết chiều rộng
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Đặt breakpoint (điểm ngắt)
          // Nếu chiều rộng khả dụng < 140px, coi là "nhỏ"
          final bool isCompact = constraints.maxWidth < 140;

          if (isCompact) {
            // 1. Layout Gọn: Chỉ Text, căn giữa theo chiều dọc
            return _buildTextColumn(isCompact: true);
          } else {
            // 2. Layout Tiêu chuẩn: Icon + Text
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildIcon(), // Hiển thị Icon
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextColumn(isCompact: false),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  /// Widget con xây dựng cột Text (Title + Value)
  Widget _buildTextColumn({required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // Nếu compact, căn giữa. 
      // Nếu không, để 'start' và 'min' (vì Row đã căn giữa rồi).
      mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
      mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: (value == 'Chưa có dữ liệu') ? 16 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
                maxLines: 1,
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  /// Widget con xây dựng Icon (Không thay đổi)
  Widget _buildIcon() {
    if (iconBgColor != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 28),
      );
    } else {
      return SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: iconColor, size: 36),
      );
    }
  }
}