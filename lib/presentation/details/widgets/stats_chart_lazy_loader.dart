import 'package:fe/presentation/details/bloc/stats_bloc.dart';
import 'package:fe/presentation/details/widgets/stats_chart_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatsChartLazyLoader extends StatelessWidget {
  const StatsChartLazyLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatsBloc, StatsState>(
      builder: (context, state) {
        switch (state.chartStatus) {
          case ChartStatus.initial:
            // Lần đầu vào tab, gọi event để fetch
            context.read<StatsBloc>().add(FetchChartData());
            return const Center(child: CircularProgressIndicator());
          case ChartStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case ChartStatus.error:
            return Center(child: Text(state.chartErrorMessage ?? 'Lỗi'));
          case ChartStatus.loaded:
            if (state.chartData == null || state.chartData!.isEmpty) {
              return const Center(child: Text('Không có dữ liệu biểu đồ'));
            }
            // Hiển thị danh sách biểu đồ
            return StatsChartList(
              charts: state.chartData!,
              selectedRange: state.selectedRange,
            );
        }
      },
    );
  }
}