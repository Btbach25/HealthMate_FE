import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/device_stats_converter.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:fe/data/repositories/stats_repository.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';

part 'stats_event.dart';
part 'stats_state.dart';

/// Bloc của màn Chỉ số sức khỏe, được tạo trong `StatsPage`.
///
/// Chiến lược dữ liệu 2 tầng: ưu tiên số liệu từ BE; nếu BE lỗi HOẶC trả về
/// rỗng thì suy ra số liệu từ cảm biến điện thoại qua [DeviceHealthCubit] +
/// `DeviceStatsConverter` và bật cờ [StatsState.isFromDevice] để UI báo cho
/// người dùng biết nguồn dữ liệu.
///
/// Vì vậy mọi lỗi mạng đều bị nuốt (`catch (_) {}`) và bloc gần như không bao
/// giờ phát [StatsStatus.error] — trường hợp xấu nhất là `loaded` với
/// `StatsPageData.empty()` để view hiện màn "Kéo xuống để tải lại".
///
/// [_deviceCubit] có thể null (ví dụ trong test hoặc khi chưa cấp quyền cảm
/// biến), khi đó fallback đơn giản là không có dữ liệu.
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
    // Đưa chartStatus về initial để tab Biểu đồ fetch lại khi được mở: dữ liệu
    // biểu đồ cũ không còn khớp với lần tải mới.
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
    // BE trả rỗng hoặc lỗi -> thử dữ liệu từ thiết bị.
    _emitDeviceFallbackOrEmpty(emit);
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
    _emitDeviceFallbackOrEmpty(emit);
  }

  /// Phần kết dùng chung của [_onFetchStatsData] và [_onChangeRange]: có dữ
  /// liệu thiết bị thì dùng, không thì emit rỗng (KHÔNG emit lỗi) để view hiện
  /// hướng dẫn "Kéo xuống để tải lại". [TryDeviceFallback] sẽ cập nhật sau nếu
  /// [DeviceHealthCubit] thu được điểm đo muộn hơn.
  void _emitDeviceFallbackOrEmpty(Emitter<StatsState> emit) {
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
    // Không ghi đè dữ liệu thật từ server: event này được bắn lặp lại mỗi khi
    // cảm biến có thêm điểm đo, kể cả khi màn hình đang hiển thị data của BE.
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

  /// Trả về `null` khi thiết bị chưa có điểm đo nào hoặc converter không dựng
  /// được chỉ số nào — người gọi phải coi `null` là "không có fallback".
  StatsPageData? _deviceFallback() {
    final points = _deviceCubit?.lastPoints ?? [];
    if (points.isEmpty) return null;
    final data = DeviceStatsConverter.toStatsPageData(
      points,
      range: state.selectedRange,
    );
    return data.metrics.isEmpty ? null : data;
  }

  Future<void> _onFetchChartData(
    FetchChartData event,
    Emitter<StatsState> emit,
  ) async {
    // Chốt chặn cho lazy loader: nó gọi event ngay trong builder, nên nếu
    // không chặn theo chartStatus thì mỗi lần rebuild sẽ fetch lại một lần.
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

    // BE trả rỗng/lỗi -> dựng biểu đồ từ dữ liệu thiết bị. Vẫn emit `loaded`
    // với danh sách rỗng để view hiện "Không có dữ liệu biểu đồ".
    final points = _deviceCubit?.lastPoints ?? [];
    final deviceCharts = points.isNotEmpty
        ? DeviceStatsConverter.toChartData(points, range: state.selectedRange)
        : <MetricChart>[];
    emit(
      state.copyWith(chartStatus: ChartStatus.loaded, chartData: deviceCharts),
    );
  }
}
