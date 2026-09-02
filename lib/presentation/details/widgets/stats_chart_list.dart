import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/presentation/details/widgets/stats_chart_card.dart';
import 'package:flutter/material.dart';

/// Danh sách cuộn các thẻ biểu đồ, mỗi [MetricChart] một [StatsChartCard].
///
/// Tham số bắt buộc:
/// - [charts]: danh sách biểu đồ đã tải xong (không xử lý trạng thái rỗng —
///   `StatsChartLazyLoader` đã chặn trước).
/// - [selectedRange]: chuyển thẳng xuống từng thẻ để chúng biết vẽ theo giờ
///   (24h) hay theo ngày.
///
/// Khi nào nên tái sử dụng: bất kỳ màn nào cần liệt kê nhiều biểu đồ chỉ số
/// theo cùng một khoảng thời gian. Padding dưới 100 là để chừa chỗ cho thanh
/// tab dưới cùng của app shell.
class StatsChartList extends StatelessWidget {
  final List<MetricChart> charts;
  final String selectedRange;

  const StatsChartList({
    super.key,
    required this.charts,
    required this.selectedRange,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: charts.length,
      itemBuilder: (context, index) {
        return StatsChartCard(
          chart: charts[index],
          selectedRange: selectedRange,
        );
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 16);
      },
    );
  }
}
