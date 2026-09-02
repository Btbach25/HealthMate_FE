import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Nhãn nhỏ "Thiết bị" cảnh báo rằng số liệu đang xem được suy ra từ cảm biến
/// điện thoại chứ không phải từ server.
///
/// Không có tham số — nơi gọi tự quyết định khi nào hiện, thường là
/// `if (state.isFromDevice) const StatsDeviceBadge()`.
///
/// Khi nào nên tái sử dụng: bất kỳ màn nào dùng cơ chế fallback dữ liệu thiết
/// bị của `StatsBloc`. Người dùng cần biết nguồn dữ liệu, đừng bỏ nhãn này khi
/// tái sử dụng luồng fallback ở màn khác.
class StatsDeviceBadge extends StatelessWidget {
  const StatsDeviceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smartphone, size: 11, color: AppColors.warning),
          SizedBox(width: 3),
          Text(
            'Thiết bị',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
