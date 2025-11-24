import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatsChartCard extends StatelessWidget {
  final MetricChart chart;
  const StatsChartCard({super.key, required this.chart});

  @override
  Widget build(BuildContext context) {
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
          // 1. Header (Giữ nguyên)
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
          const SizedBox(height: 24),

          // 2. Biểu đồ
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              _buildChartData(),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    if (chart.points.isEmpty) {
      return LineChartData();
    }

    // --- XỬ LÝ DỮ LIỆU (Giữ nguyên logic của bạn) ---
    final spots = chart.points.map((point) {
      return FlSpot(point.time.millisecondsSinceEpoch.toDouble(), point.value);
    }).toList();

    final minY = chart.points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxY = chart.points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    double minX = spots.first.x;
    double maxX = spots.last.x;

    if (spots.length > 1) {
      final span = spots.last.x - spots.first.x;
      final padding = span * 0.1;
      minX -= padding;
      maxX += padding;
    } else {
      const oneDay = 86400000;
      minX -= oneDay;
      maxX += oneDay;
    }

    // --- STYLE GRADIENT (Lấy cảm hứng từ Sample 2) ---
    // Tạo gradient từ màu chính của chart (ví dụ: chart.lineColor -> màu nhạt hơn của nó)
    // Nếu bạn muốn màu cố định như sample thì thay list này bằng [AppColors.contentColorCyan, AppColors.contentColorBlue]
    final List<Color> gradientColors = [
      chart.lineColor,
      chart.lineColor.withOpacity(0.5), // Pha thêm chút trong suốt hoặc màu thứ 2
    ];

    return LineChartData(
      clipData: const FlClipData.none(),
      
      // --- INTERACTION (Giữ nguyên logic Tooltip của bạn) ---
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot spot) => Colors.white.withOpacity(0.9),
          tooltipBorder: BorderSide(color: chart.lineColor, width: 2),
          tooltipBorderRadius: BorderRadius.circular(8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((barSpot) {
              final point = chart.points[barSpot.spotIndex];
              final date = DateFormat('dd/MM/yyyy').format(point.time);
              return LineTooltipItem(
                'Ngày: $date\n',
                const TextStyle(color: AppColors.textBlack, fontSize: 12),
                children: [
                  TextSpan(
                    text: '${chart.title.split(' ')[0]}: ${point.value.toStringAsFixed(0)} ${chart.unit}',
                    style: TextStyle(
                      color: chart.lineColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
                textAlign: TextAlign.left,
              );
            }).toList();
          },
        ),
      ),

      // --- AXIS & GRID ---
      gridData: FlGridData(
        show: false, // Sample có grid, nhưng chart nhỏ (Card) thì nên tắt cho thoáng
        drawVerticalLine: false,
      ),
      borderData: FlBorderData(show: false),

      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (maxX - minX) / 4, // Chia trục X làm 4 khoảng
            getTitlesWidget: (double value, TitleMeta meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              // Chỉ hiển thị label nếu không quá sát lề
              if (value == minX || value == maxX) return const SizedBox.shrink(); 
              
              return SideTitleWidget(
                meta: meta,
                space: 8,
                child: Text(
                  DateFormat('d MMM', 'vi').format(date),
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      minX: minX,
      maxX: maxX,
      minY: minY - (maxY - minY) * 0.1, // Thêm padding dưới một chút
      maxY: maxY + (maxY - minY) * 0.1, // Thêm padding trên một chút

      // --- LINE DATA (ÁP DỤNG STYLE SAMPLE 2) ---
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true, // Đường cong mềm mại
          
          // 1. Thay color bằng gradient
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          
          barWidth: 5, // Tăng độ dày line lên 5 như sample
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          
          // 2. Thêm hiệu ứng đổ màu bên dưới (Below Bar Data)
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3)) // Độ trong suốt giảm dần
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}