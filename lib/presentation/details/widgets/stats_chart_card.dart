import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Một điểm đã chuẩn hoá để vẽ cột: dùng chung cho cả dữ liệu thô (24h) lẫn
/// dữ liệu đã gộp theo ngày, nhờ vậy chỉ cần một hàm dựng biểu đồ.
typedef _ChartPoint = ({DateTime time, double value});

/// Thẻ biểu đồ cột cho MỘT loại chỉ số: tiêu đề, số điểm dữ liệu, ba số tóm
/// tắt (thấp nhất / mới nhất / cao nhất) và biểu đồ.
///
/// Tham số bắt buộc:
/// - [chart]: dữ liệu biểu đồ của một chỉ số (điểm đo, đơn vị, màu đường).
/// - [selectedRange]: '24h' | '7d' | '30d'. Quyết định cách gom dữ liệu:
///   '24h' vẽ từng lần đo theo giờ, các range dài hơn gộp trung bình theo ngày
///   để 30 ngày không biến thành hàng trăm cột dính nhau.
///
/// Khi nào nên tái sử dụng: bất cứ đâu cần hiển thị lịch sử một chỉ số dạng
/// cột — màn Chỉ số và dialog chi tiết thành viên gia đình đang dùng chung
/// widget này. Thẻ tự lo mọi việc gom nhóm/định dạng nhãn, nơi gọi chỉ cần
/// truyền dữ liệu thô.
class StatsChartCard extends StatelessWidget {
  final MetricChart chart;
  final String selectedRange;

  const StatsChartCard({
    super.key,
    required this.chart,
    required this.selectedRange,
  });

  /// Dữ liệu thô đã sắp theo thời gian — BE không đảm bảo thứ tự.
  List<_ChartPoint> _sortedPoints() {
    return (chart.points.map((p) => (time: p.time, value: p.value)).toList()
      ..sort((a, b) => a.time.compareTo(b.time)));
  }

  /// Gộp trung bình các lần đo trong cùng một ngày.
  ///
  /// Gom theo chuỗi 'yyyy-MM-dd' (không phải theo đối tượng DateTime) để hai
  /// lần đo cùng ngày khác giờ vẫn rơi vào một nhóm.
  List<_ChartPoint> _aggregateByDay() {
    final Map<String, List<double>> grouped = {};
    final dateKey = DateFormat('yyyy-MM-dd');
    for (final point in chart.points) {
      grouped.putIfAbsent(dateKey.format(point.time), () => []).add(point.value);
    }
    return (grouped.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return (time: DateTime.parse(e.key), value: avg);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time)));
  }

  @override
  Widget build(BuildContext context) {
    final values = chart.points.map((p) => p.value).toList();
    final minVal = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final latestVal = chart.points.isEmpty ? 0.0 : chart.points.last.value;

    final is24h = selectedRange == '24h';
    final points = is24h ? _sortedPoints() : _aggregateByDay();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  chart.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${chart.dataPointCount} điểm',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (chart.points.isNotEmpty)
            Row(
              children: [
                _buildSummaryItem('Thấp nhất', minVal),
                _buildSummaryItem('Mới nhất', latestVal, highlight: true),
                _buildSummaryItem('Cao nhất', maxVal),
              ],
            ),

          const SizedBox(height: 16),

          if (points.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                _buildBarData(
                  points,
                  maxVal,
                  axisFormat: DateFormat(is24h ? 'HH:mm' : 'd/M'),
                  tooltipFormat: DateFormat(is24h ? 'HH:mm' : 'dd/MM/yyyy'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, {bool highlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: highlight ? chart.lineColor : AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$label\n${chart.unit}',
            style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Dựng cấu hình biểu đồ cột dùng chung cho cả hai chế độ.
  ///
  /// Trước đây có hai hàm gần như giống hệt (một cho 24h, một cho theo ngày);
  /// chúng chỉ khác nguồn dữ liệu và định dạng nhãn nên được gộp lại, với
  /// [axisFormat] cho nhãn trục X và [tooltipFormat] cho tiêu đề tooltip.
  ///
  /// [maxVal] là giá trị lớn nhất của dữ liệu THÔ (không phải của [data]) — cố
  /// ý như vậy để trần biểu đồ ở chế độ gộp theo ngày vẫn phản ánh đỉnh thật.
  BarChartData _buildBarData(
    List<_ChartPoint> data,
    double maxVal, {
    required DateFormat axisFormat,
    required DateFormat tooltipFormat,
  }) {
    final barGroups = data.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: chart.lineColor,
            width: _barWidth(data.length),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            // Cột nền mờ cao bằng trần biểu đồ, tạo cảm giác "máng chứa" để
            // mắt so sánh được các cột thấp.
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVal * 1.15,
              color: chart.lineColor.withValues(alpha: 0.07),
            ),
          ),
        ],
      );
    }).toList();

    // Chỉ vẽ tối đa ~6 nhãn trục X để chúng không đè lên nhau.
    final labelStep = (data.length / 6).ceil().clamp(1, data.length);

    return BarChartData(
      // Trần cao hơn giá trị lớn nhất 15% để cột cao nhất không chạm mép trên.
      maxY: maxVal * 1.15,
      barGroups: barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxVal * 0.5,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.cardBorder,
          strokeWidth: 1,
          dashArray: [4, 6],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index % labelStep != 0) return const SizedBox.shrink();
              // fl_chart có thể hỏi nhãn cho vị trí ngoài dải dữ liệu.
              if (index >= data.length) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(
                  axisFormat.format(data[index].time),
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.white.withValues(alpha: 0.95),
          tooltipBorder: BorderSide(color: chart.lineColor, width: 1.5),
          tooltipBorderRadius: BorderRadius.circular(8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final point = data[group.x];
            return BarTooltipItem(
              '${tooltipFormat.format(point.time)}\n',
              const TextStyle(color: AppColors.textBlack, fontSize: 11),
              children: [
                TextSpan(
                  text: '${rod.toY.toStringAsFixed(0)} ${chart.unit}',
                  style: TextStyle(
                    color: chart.lineColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Cột càng nhiều càng mảnh để không tràn khỏi bề ngang thẻ.
  double _barWidth(int count) {
    if (count <= 7) return 18;
    if (count <= 14) return 12;
    if (count <= 30) return 7;
    return 4;
  }
}
