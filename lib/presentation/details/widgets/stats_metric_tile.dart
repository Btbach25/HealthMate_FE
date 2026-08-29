import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/enums/metric_status.dart';
import 'package:fe/data/models/details/metric_summary.dart';
import 'package:fe/presentation/details/widgets/stats_metric_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Một dòng chỉ số sức khỏe: icon theo loại, tên, dòng phụ, và giá trị mới
/// nhất kèm đơn vị.
///
/// Tham số bắt buộc:
/// - [metric]: dữ liệu tóm tắt của một loại chỉ số.
/// - [mode]: quyết định dòng phụ hiển thị xu hướng hay tình trạng —
///   xem [MetricDisplayMode].
///
/// Khi nào nên tái sử dụng: mọi nơi cần liệt kê chỉ số sức khỏe theo dòng
/// (màn Chỉ số, dialog xem chi tiết thành viên gia đình). Widget tự chọn icon
/// và màu theo loại chỉ số nên nơi gọi không cần truyền gì thêm.
class StatsMetricTile extends StatelessWidget {
  final MetricSummary metric;
  final MetricDisplayMode mode;

  const StatsMetricTile({
    super.key,
    required this.metric,
    required this.mode,
  });

  /// Suy ra loại chỉ số để chọn icon/màu.
  ///
  /// Hợp đồng với BE: trường phân loại không đáng tin — BE trả 'heart' cho
  /// nhiều loại khác nhau — nên phải đoán lại từ tiêu đề và đơn vị. Vì tiêu đề
  /// có thể là tiếng Việt hoặc tiếng Anh tuỳ endpoint, mỗi nhánh kiểm tra cả
  /// hai. Không khớp gì thì mặc định là nhịp tim.
  String _metricKey() {
    final t = metric.title.toLowerCase();
    final u = metric.unit.toLowerCase();
    if (t.contains('huyết áp') || t.contains('blood') || u == 'mmhg') return 'bp';
    if (t.contains('spo2') || t.contains('oxy') || t.contains('o2')) return 'spo2';
    if (t.contains('nhiệt') || t.contains('temp') || u == '°c') return 'temp';
    if (t.contains('cân') || t.contains('weight') || u == 'kg') return 'weight';
    if (t.contains('bước') || t.contains('step')) return 'steps';
    if (t.contains('ngủ') || t.contains('sleep') || u == 'giờ') return 'sleep';
    return 'heart';
  }

  @override
  Widget build(BuildContext context) {
    final String lastUpdateFormatted =
        DateFormat('dd/MM/yyyy').format(metric.lastUpdate);

    const valueStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.textBlack,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIcon(_metricKey()),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metric.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (mode == MetricDisplayMode.trend)
                  _buildTrendInfo(lastUpdateFormatted)
                else
                  _buildStatusInfo(lastUpdateFormatted),
              ],
            ),
          ),
          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                metric.latestValue.toStringAsFixed(0),
                style: valueStyle,
              ),
              Text(
                metric.unit,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dòng phụ chế độ "xu hướng": số lần đo, ngày cập nhật và % thay đổi.
  ///
  /// Màu của % không theo dấu tăng/giảm mà theo [MetricSummary.isIncreaseGood]:
  /// cân nặng tăng là xấu (đỏ) trong khi số bước tăng là tốt (xanh). Mũi tên
  /// thì vẫn theo dấu thật của [MetricSummary.trendPercentage].
  Widget _buildTrendInfo(String lastUpdateFormatted) {
    final trend = metric.trendPercentage;
    if (trend == null || trend == 0) {
      return Text(
        '${metric.readingCount} lần đo • $lastUpdateFormatted',
        style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    bool isGoodTrend = (metric.isIncreaseGood && trend > 0) ||
                       (!metric.isIncreaseGood && trend < 0);

    final Color trendColor = isGoodTrend ? AppColors.primary : AppColors.error;
    final IconData trendIcon = trend > 0 ? AppIcons.trendUp : AppIcons.trendDown;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${metric.readingCount} lần đo • $lastUpdateFormatted',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Icon(trendIcon, color: trendColor, size: 14),
        Text(
          '${trend.toStringAsFixed(1)}%',
          style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Dòng phụ chế độ "tình trạng": ngày cập nhật + nhãn màu theo
  /// [MetricSummary.status]. Mặc định coi là bình thường khi BE không phân
  /// loại được.
  Widget _buildStatusInfo(String lastUpdateFormatted) {
    Color tagBgColor = AppColors.tagNormalBg;
    Color tagTextColor = AppColors.tagNormalText;
    String tagText = 'Bình thường';

    if (metric.status == MetricStatus.warning) {
      tagBgColor = AppColors.tagWarningBg;
      tagTextColor = AppColors.tagWarningText;
      tagText = 'Cần chú ý';
    } else if (metric.status == MetricStatus.danger) {
      tagBgColor = AppColors.tagUrgentBg;
      tagTextColor = AppColors.tagUrgentText;
      tagText = 'Nguy hiểm';
    }

    return Row(
      children: [
        Text(
          lastUpdateFormatted,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: tagBgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tagText,
            style: TextStyle(
              color: tagTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Icon + màu nền theo key trả về từ [_metricKey].
  Widget _buildIcon(String key) {
    final IconData icon;
    final Color color;
    final Color bg;
    switch (key) {
      case 'bp':
        icon = AppIcons.bloodPressure; color = AppColors.primary;       bg = AppColors.primaryContainer;
      case 'spo2':
        icon = AppIcons.spo2;          color = AppColors.info;           bg = AppColors.infoLight;
      case 'temp':
        icon = AppIcons.temperature;   color = AppColors.tempIconColor;  bg = AppColors.tempIconBg;
      case 'weight':
        icon = AppIcons.weight;        color = AppColors.weightIconColor; bg = AppColors.weightIconBg;
      case 'steps':
        icon = AppIcons.steps;         color = AppColors.success;        bg = AppColors.successLight;
      case 'sleep':
        icon = AppIcons.sleep;         color = const Color(0xFF5C6BC0);  bg = const Color(0xFFE8EAF6);
      default:
        icon = AppIcons.heart;         color = AppColors.heartIconColor; bg = AppColors.heartIconBg;
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
