import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/device_stats_converter.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:fe/data/repositories/stats_repository.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';

part 'stats_event.dart';
part 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StatsRepository _statsRepository;
  final DeviceHealthCubit? _deviceCubit;

  StatsBloc({
    required StatsRepository statsRepository,
    DeviceHealthCubit? deviceCubit,
  }) : _statsRepository = statsRepository,
       _deviceCubit = deviceCubit,
       super(StatsState.initial()) {
    on<FetchStatsData>(_onFetchStatsData);
    on<FetchChartData>(_onFetchChartData);
    on<ChangeStatsRange>(_onChangeRange);
    on<TryDeviceFallback>(_onTryDeviceFallback);
  }

  Future<void> _onFetchStatsData(
    FetchStatsData event,
    Emitter<StatsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StatsStatus.loading,
        chartStatus: ChartStatus.initial,
        chartData: null,
        isFromDevice: false,
      ),
    );
    try {
      final statsData = await _statsRepository.getStatsPageData(
        range: state.selectedRange,
      );
      if (statsData.metrics.isNotEmpty) {
        emit(
          state.copyWith(
            status: StatsStatus.loaded,
            statsData: statsData,
            isFromDevice: false,
          ),
        );
        return;
      }
    } catch (_) {}
    // BE trả empty hoặc lỗi → thử device fallback
    final fallback = _deviceFallback();
    if (fallback != null) {
      emit(
        state.copyWith(
          status: StatsStatus.loaded,
          statsData: fallback,
          isFromDevice: true,
        ),
      );
    } else {
      // Device data chưa sẵn sàng → emit empty để view hiện "Kéo xuống"
      // TryDeviceFallback sẽ cập nhật khi DeviceHealthCubit hoàn thành
      emit(
        state.copyWith(
          status: StatsStatus.loaded,
          statsData: StatsPageData.empty(),
          isFromDevice: false,
        ),
      );
    }
  }

  Future<void> _onChangeRange(
    ChangeStatsRange event,
    Emitter<StatsState> emit,
  ) async {
    if (event.range == state.selectedRange) return;
    emit(
      state.copyWith(
        selectedRange: event.range,
        status: StatsStatus.loading,
        chartStatus: ChartStatus.initial,
        chartData: null,
      ),
    );
    try {
      final statsData = await _statsRepository.getStatsPageData(
        range: event.range,
      );
      if (statsData.metrics.isNotEmpty) {
        emit(
          state.copyWith(
            status: StatsStatus.loaded,
            statsData: statsData,
            isFromDevice: false,
          ),
        );
        return;
      }
    } catch (_) {}
    final fallback = _deviceFallback();
    if (fallback != null) {
      emit(
        state.copyWith(
          status: StatsStatus.loaded,
          statsData: fallback,
          isFromDevice: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: StatsStatus.loaded,
          statsData: StatsPageData.empty(),
          isFromDevice: false,
        ),
      );
    }
  }

  void _onTryDeviceFallback(TryDeviceFallback event, Emitter<StatsState> emit) {
    // Bỏ qua nếu đã có data thật từ server
    final hasServerData =
        state.status == StatsStatus.loaded &&
        !state.isFromDevice &&
        (state.statsData?.metrics.isNotEmpty ?? false);
    if (hasServerData) return;

    final fallback = _deviceFallback();
    if (fallback != null) {
      emit(
        state.copyWith(
          status: StatsStatus.loaded,
          statsData: fallback,
          isFromDevice: true,
        ),
      );
    }
  }

  StatsPageData? _deviceFallback({String? range}) {
    final points = _deviceCubit?.lastPoints ?? [];
    if (points.isEmpty) return null;
    final data = DeviceStatsConverter.toStatsPageData(
      points,
      range: range ?? state.selectedRange,
    );
    return data.metrics.isEmpty ? null : data;
  }

  Future<void> _onFetchChartData(
    FetchChartData event,
    Emitter<StatsState> emit,
  ) async {
    if (state.chartStatus != ChartStatus.initial) return;

    emit(state.copyWith(chartStatus: ChartStatus.loading));
    try {
      final chartData = await _statsRepository.getChartData(
        range: state.selectedRange,
      );
      if (chartData.isNotEmpty) {
        emit(
          state.copyWith(chartStatus: ChartStatus.loaded, chartData: chartData),
        );
        return;
      }
    } catch (_) {}

    // BE trả empty/lỗi → fallback device
    final points = _deviceCubit?.lastPoints ?? [];
    final deviceCharts = points.isNotEmpty
        ? DeviceStatsConverter.toChartData(points, range: state.selectedRange)
        : <MetricChart>[];
    emit(
      state.copyWith(chartStatus: ChartStatus.loaded, chartData: deviceCharts),
    );
  }
}
