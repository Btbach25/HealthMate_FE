import 'package:fe/data/models/details/metric_summary.dart';
import 'package:fe/presentation/details/widgets/stats_metric_tile.dart';
import 'package:flutter/material.dart';

/// Cách một [StatsMetricTile] trình bày dòng thông tin phụ:
/// - [trend]: số lần đo + ngày cập nhật + % tăng/giảm (tab "Gần đây").
/// - [status]: ngày cập nhật + nhãn Bình thường/Cần chú ý/Nguy hiểm
///   (tab "Tổng quan").
enum MetricDisplayMode { trend, status }

/// Danh sách cuộn các chỉ số sức khỏe.
///
/// Tham số bắt buộc:
/// - [metrics]: danh sách chỉ số đã tải xong.
/// - [displayMode]: chọn kiểu hiển thị cho toàn bộ danh sách.
///
/// Khi nào nên tái sử dụng: hai tab đầu của màn Chỉ số dùng chung widget này,
/// chỉ khác [displayMode] — cần thêm một cách trình bày mới thì thêm giá trị
/// vào [MetricDisplayMode] thay vì viết list mới. Padding dưới 100 chừa chỗ
/// cho thanh tab dưới cùng.
class StatsMetricList extends StatelessWidget {
  final List<MetricSummary> metrics;
  final MetricDisplayMode displayMode;

  const StatsMetricList({
    super.key,
    required this.metrics,
    required this.displayMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        return StatsMetricTile(
          metric: metrics[index],
          mode: displayMode,
        );
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
    );
  }
}
