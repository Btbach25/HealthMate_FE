import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/models/details/chart_data_point.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatsChartCard extends StatelessWidget {
  final MetricChart chart;
  final String selectedRange;

  const StatsChartCard({
    super.key,
    required this.chart,
    required this.selectedRange,
  });

  List<ChartDataPoint> _sortedPoints() {
    return (List<ChartDataPoint>.from(chart.points)
      ..sort((a, b) => a.time.compareTo(b.time)));
  }

  List<({DateTime date, double value})> _aggregateByDay() {
    final Map<String, List<double>> grouped = {};
    final dateKey = DateFormat('yyyy-MM-dd');
    for (final point in chart.points) {
      grouped.putIfAbsent(dateKey.format(point.time), () => []).add(point.value);
    }
    return (grouped.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return (date: DateTime.parse(e.key), value: avg);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date)));
  }

  @override
  Widget build(BuildContext context) {
    final values = chart.points.map((p) => p.value).toList();
    final minVal = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final latestVal = chart.points.isEmpty ? 0.0 : chart.points.last.value;

    final is24h = selectedRange == '24h';
    final pts = is24h ? _sortedPoints() : <ChartDataPoint>[];
    final daily = is24h ? <({DateTime date, double value})>[] : _aggregateByDay();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                chart.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${chart.dataPointCount} điểm dữ liệu',
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Thấp nhất', minVal),
                _buildSummaryItem('Mới nhất', latestVal, highlight: true),
                _buildSummaryItem('Cao nhất', maxVal),
              ],
            ),

          const SizedBox(height: 16),

          if (is24h && pts.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(_buildRawBarData(pts, maxVal)),
            )
          else if (!is24h && daily.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(_buildBarData(daily, maxVal)),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, {bool highlight = false}) {
    return Column(
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
          '$label (${chart.unit})',
          style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
        ),
      ],
    );
  }

  // 24h: mỗi cột = một điểm đo, trục x là HH:mm
  BarChartData _buildRawBarData(List<ChartDataPoint> pts, double maxVal) {
    final barGroups = pts.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.value,
            color: chart.lineColor,
            width: _barWidth(pts.length),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVal * 1.15,
              color: chart.lineColor.withValues(alpha: 0.07),
            ),
          ),
        ],
      );
    }).toList();

    final labelStep = (pts.length / 6).ceil().clamp(1, pts.length);

    return BarChartData(
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
              final idx = value.toInt();
              if (idx % labelStep != 0) return const SizedBox.shrink();
              if (idx >= pts.length) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(
                  DateFormat('HH:mm').format(pts[idx].time),
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
            final pt = pts[group.x];
            return BarTooltipItem(
              '${DateFormat('HH:mm').format(pt.time)}\n',
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

  BarChartData _buildBarData(
    List<({DateTime date, double value})> dailyData,
    double maxVal,
  ) {
    final barGroups = dailyData.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: chart.lineColor,
            width: _barWidth(dailyData.length),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVal * 1.15,
              color: chart.lineColor.withValues(alpha: 0.07),
            ),
          ),
        ],
      );
    }).toList();

    final labelStep = (dailyData.length / 6).ceil().clamp(1, dailyData.length);

    return BarChartData(
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
              if (index >= dailyData.length) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(
                  DateFormat('d/M').format(dailyData[index].date),
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
            final day = dailyData[group.x];
            return BarTooltipItem(
              '${DateFormat('dd/MM/yyyy').format(day.date)}\n',
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

  double _barWidth(int count) {
    if (count <= 7) return 18;
    if (count <= 14) return 12;
    if (count <= 30) return 7;
    return 4;
  }
}
