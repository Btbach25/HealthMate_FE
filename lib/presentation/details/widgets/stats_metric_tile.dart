import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/enums/metric_status.dart';
import 'package:fe/data/models/details/metric_summary.dart';
import 'package:fe/presentation/details/widgets/stats_metric_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatsMetricTile extends StatelessWidget {
  final MetricSummary metric;
  final MetricDisplayMode mode;

  const StatsMetricTile({
    super.key,
    required this.metric,
    required this.mode,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'steps': return AppIcons.steps;
      case 'heart': return AppIcons.heart;
      case 'weight': return AppIcons.weight;
      case 'sleep': return AppIcons.sleep;
      default: return AppIcons.stats;
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIcon(_getIconData(metric.iconName)),
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
  
  Widget _buildIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 28),
    );
  }
}