import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:fe/data/repositories/stats_repository.dart';

part 'stats_event.dart';
part 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StatsRepository _statsRepository;

  StatsBloc({required StatsRepository statsRepository})
    : _statsRepository = statsRepository,
      super(StatsState.initial()) {
    // Đăng ký trình xử lý sự kiện
    on<FetchStatsData>(_onFetchStatsData);
    on<FetchChartData>(_onFetchChartData);
  }

  Future<void> _onFetchStatsData(
    FetchStatsData event,
    Emitter<StatsState> emit,
  ) async {
    // 1. Emit trạng thái Loading
    emit(state.copyWith(status: StatsStatus.loading));
    try {
      // 2. Gọi Repository để lấy dữ liệu
      final statsData = await _statsRepository.getStatsPageData();

      // 3. Emit trạng thái Loaded với dữ liệu mới
      emit(state.copyWith(status: StatsStatus.loaded, statsData: statsData));
    } catch (e) {
      // 4. Emit trạng thái Error nếu có lỗi
      emit(
        state.copyWith(status: StatsStatus.error, errorMessage: e.toString()),
      );
    }
  }
  Future<void> _onFetchChartData(
      FetchChartData event,
      Emitter<StatsState> emit,
    ) async {
      // Chỉ fetch nếu chưa fetch lần nào
      if (state.chartStatus != ChartStatus.initial) return;

      emit(state.copyWith(chartStatus: ChartStatus.loading));
      try {
        final chartData = await _statsRepository.getChartData();
        emit(state.copyWith(
          chartStatus: ChartStatus.loaded,
          chartData: chartData,
        ));
      } catch (e) {
        emit(state.copyWith(
          chartStatus: ChartStatus.error,
          chartErrorMessage: UserFacingError.message(e),
        ));
      }
    }
}