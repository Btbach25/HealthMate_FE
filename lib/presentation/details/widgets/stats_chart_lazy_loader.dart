import 'package:fe/presentation/details/bloc/stats_bloc.dart';
import 'package:fe/presentation/details/widgets/stats_chart_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Nội dung tab "Biểu đồ" — chỉ tải dữ liệu khi tab được mở lần đầu.
///
/// Không nhận tham số; **bắt buộc** đặt dưới một `BlocProvider<StatsBloc>`.
///
/// Cách hoạt động: `ChartStatus.initial` vừa là trạng thái "chưa tải" vừa là
/// tín hiệu kích hoạt fetch. Vì `TabBarView` chỉ build tab khi người dùng
/// chuyển tới, dữ liệu biểu đồ (thường nặng) không bị tải cùng lúc với danh
/// sách chỉ số.
///
/// Cạm bẫy: event được bắn ngay trong `builder`. An toàn vì `StatsBloc` bỏ qua
/// `FetchChartData` khi `chartStatus != initial`, nếu bỏ chốt chặn đó đi thì
/// mỗi lần rebuild sẽ gọi API một lần.
///
/// Khi nào nên tái sử dụng: làm mẫu cho các tab khác cần lazy-load — nhân đôi
/// cặp `status` riêng cho từng vùng dữ liệu thay vì dùng chung một status.
class StatsChartLazyLoader extends StatelessWidget {
  const StatsChartLazyLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatsBloc, StatsState>(
      builder: (context, state) {
        switch (state.chartStatus) {
          case ChartStatus.initial:
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
            return StatsChartList(
              charts: state.chartData!,
              selectedRange: state.selectedRange,
            );
        }
      },
    );
  }
}
