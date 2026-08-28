import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:flutter/material.dart';

/// Thẻ tóm tắt nằm dưới tiêu đề màn Chỉ số: icon + hai chip đếm nhanh.
///
/// Tham số bắt buộc:
/// - [totalReadings]: tổng số lần đo trong khoảng thời gian đang chọn.
/// - [totalTypes]: số loại chỉ số khác nhau.
///
/// Cả hai đều là số đã tính sẵn ở `StatsPageData`; widget không tự cộng lại từ
/// danh sách chỉ số.
///
/// Khi nào nên tái sử dụng: đầu các màn thống kê cần một dòng "tổng quan"
/// ngắn. Muốn thêm chip thì thêm vào Row bên trong — `_Chip` là private nên
/// nếu cần dùng ở nơi khác hãy tách nó ra widget riêng.
class StatsHeaderCard extends StatelessWidget {
  final int totalReadings;
  final int totalTypes;

  const StatsHeaderCard({
    super.key,
    required this.totalReadings,
    required this.totalTypes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              AppIcons.statsHeader,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tổng quan sức khỏe',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Chip(label: '$totalReadings lần đo'),
                    const SizedBox(width: 8),
                    _Chip(label: '$totalTypes loại chỉ số'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textGrey,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
