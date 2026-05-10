import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/presentation/details/widgets/stats_chart_card.dart';
import 'package:flutter/material.dart';

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
        return StatsChartCard(chart: charts[index], selectedRange: selectedRange);
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 16);
      },
    );
  }
}