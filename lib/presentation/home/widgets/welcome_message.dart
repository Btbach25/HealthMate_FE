import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Lời chào đầu màn hình kèm ngày hôm nay, ví dụ "Chào buổi sáng, An! 👋".
///
/// [name] là tên hiển thị của người dùng; phía gọi tự quyết định lấy từ đâu.
///
/// Tái sử dụng được ở bất kỳ màn hình nào cần một tiêu đề chào hỏi: widget không phụ
/// thuộc bloc nào, chỉ đọc [DateTime.now]. Đổi lại, nó không tự cập nhật khi đồng hồ
/// vượt qua mốc giờ hay sang ngày mới — chỉ đúng tại thời điểm build.
class WelcomeMessage extends StatelessWidget {
  final String name;
  const WelcomeMessage({super.key, required this.name});

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    return '${weekdays[now.weekday - 1]}, ${now.day}/${now.month}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlack,
            ),
            children: [
              TextSpan(text: '${_timeGreeting()}, '),
              TextSpan(
                text: name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '! 👋'),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          _todayLabel(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}