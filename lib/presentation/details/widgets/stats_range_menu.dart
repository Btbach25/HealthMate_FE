import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Nút "pill" mở menu chọn khoảng thời gian (24 giờ / 7 ngày / 30 ngày).
///
/// Tham số bắt buộc:
/// - [selectedRange]: mã range đang chọn, dùng chính chuỗi mà BE hiểu
///   ('24h' | '7d' | '30d').
/// - [ranges]: danh sách mã range cho vào menu — thường là
///   `StatsState.availableRanges`.
/// - [onSelected]: gọi lại với mã range người dùng chọn. Widget KHÔNG tự đổi
///   state; nơi gọi chịu trách nhiệm bắn event cho bloc.
///
/// Widget cố ý không phụ thuộc bloc nào để có thể dùng lại ở mọi màn thống kê
/// (và test được mà không cần dựng bloc).
class StatsRangeMenu extends StatelessWidget {
  final String selectedRange;
  final List<String> ranges;
  final ValueChanged<String> onSelected;

  const StatsRangeMenu({
    super.key,
    required this.selectedRange,
    required this.ranges,
    required this.onSelected,
  });

  /// Đổi mã range của BE sang nhãn tiếng Việt. Mã lạ được hiển thị nguyên văn
  /// thay vì làm vỡ giao diện, phòng khi BE thêm range mới.
  static String rangeLabel(String range) {
    switch (range) {
      case '24h':
        return '24 giờ';
      case '7d':
        return '7 ngày';
      case '30d':
        return '30 ngày';
      default:
        return range;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selectedRange,
      onSelected: onSelected,
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      itemBuilder: (_) => ranges.map((r) {
        final active = r == selectedRange;
        return PopupMenuItem<String>(
          value: r,
          child: Row(
            children: [
              // Ô cố định 20px giữ chỗ cho dấu tick, để nhãn của mọi dòng
              // thẳng hàng dù chỉ một dòng có tick.
              SizedBox(
                width: 20,
                child: active
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                rangeLabel(r),
                style: TextStyle(
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? AppColors.primary : AppColors.textBlack,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rangeLabel(selectedRange),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
