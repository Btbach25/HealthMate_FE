import 'package:fe/data/models/details/metric_summary.dart';
import 'package:fe/presentation/details/widgets/stats_metric_tile.dart';
import 'package:flutter/material.dart';

enum MetricDisplayMode { trend, status }

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