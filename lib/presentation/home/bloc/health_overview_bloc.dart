import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/data/models/health/blood_pressure.dart';
import 'package:fe/data/models/health/health_overview.dart';
import 'package:fe/data/models/health/heart_rate.dart';
import 'package:fe/data/repositories/health_repository.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';

part 'health_overview_event.dart';
part 'health_overview_state.dart';

/// Gộp hai nguồn chỉ số sức khoẻ thành một [HealthOverview] duy nhất cho UI:
/// dữ liệu từ backend và dữ liệu đọc trực tiếp từ thiết bị qua [DeviceHealthCubit].
///
/// Máy trạng thái:
///
///   initial --HealthOverviewRequested--> loading --+-- BE trả về -> success (nguồn = BE)
///                                                  +-- BE lỗi ----+-- đã có overview -> success (giữ nguyên)
///                                                                 +-- chưa có -------> failure
///
///   (bất kỳ lúc nào) HealthOverviewDeviceLoaded  -> success, nhưng chỉ ghi đè khi
///                    overview hiện tại chưa phải của backend.
///   (bất kỳ lúc nào) HealthOverviewManualPatched -> success, ghi đè vô điều kiện.
///
/// Ai bắn event:
/// - [HealthOverviewSection] bắn [HealthOverviewRequested] trong post-frame callback
///   của `initState`, và [HealthOverviewRetried] khi người dùng bấm "Thử lại".
/// - Chính bloc này bắn [HealthOverviewDeviceLoaded] từ subscription vào
///   [DeviceHealthCubit.stream] mở trong constructor.
/// - Dialog nhập tay trong `widgets/metric_carousel.dart` bắn
///   [HealthOverviewManualPatched] để cập nhật lạc quan ngay sau khi đẩy WebSocket
///   thành công, khỏi phải chờ vòng poll kế tiếp.
///
/// Quy tắc ưu tiên: dữ liệu backend luôn thắng dữ liệu thiết bị (xem [_isDeviceOverview]).
///
/// Vòng đời: bloc mở subscription trong constructor nên **bắt buộc** phải được
/// scope theo màn hình và đóng lại; xem cách [HomeView] provide nó.
class HealthOverviewBloc extends Bloc<HealthOverviewEvent, HealthOverviewState> {
  final HealthRepository _repository;
  final DeviceHealthCubit _deviceCubit;
  StreamSubscription<DeviceHealthState>? _deviceSub;

  HealthOverviewBloc({
    required HealthRepository repository,
    required DeviceHealthCubit deviceCubit,
  })  : _repository = repository,
        _deviceCubit = deviceCubit,
        super(const HealthOverviewState()) {
    on<HealthOverviewRequested>(_onRequested);
    on<HealthOverviewRetried>(_onRetried);
    on<HealthOverviewDeviceLoaded>(_onDeviceLoaded);
    on<HealthOverviewManualPatched>(_onManualPatched);

    // Cubit sống ở app-level nên rất có thể đã poll xong trước khi bloc này ra đời.
    // Stream chỉ phát các state *tương lai*, vì vậy phải đọc state hiện tại một lần
    // ở đây, nếu không màn hình sẽ trống cho tới lần poll kế tiếp.
    if (_deviceCubit.lastPoints.isNotEmpty) {
      final ov = _deviceCubit.deviceHealthOverview;
      if (ov != null) { add(HealthOverviewDeviceLoaded(ov)); }
    }

    // Sau đó bám theo stream để bắt các lần poll tiếp theo.
    _deviceSub = _deviceCubit.stream.listen((deviceState) {
      if (deviceState.dataCount > 0) {
        final ov = _deviceCubit.deviceHealthOverview;
        if (ov != null) { add(HealthOverviewDeviceLoaded(ov)); }
      }
    });
  }

  Future<void> _onRequested(HealthOverviewRequested event, Emitter<HealthOverviewState> emit) async {
    emit(state.copyWith(status: HealthOverviewStatus.loading));
    try {
      final overview = await _repository.getOverview();
      emit(state.copyWith(status: HealthOverviewStatus.success, overview: overview));
    } catch (e) {
      // Đã có sẵn dữ liệu (thường là từ thiết bị) thì không hạ xuống failure:
      // người dùng vẫn đang thấy số liệu thật, hiện banner lỗi lúc này chỉ gây hoang mang.
      if (state.overview != null) {
        emit(state.copyWith(status: HealthOverviewStatus.success));
      } else {
        emit(state.copyWith(
          status: HealthOverviewStatus.failure,
          errorMessage: UserFacingError.message(e),
        ));
      }
    }
  }

  Future<void> _onRetried(HealthOverviewRetried event, Emitter<HealthOverviewState> emit) async {
    add(const HealthOverviewRequested());
  }

  void _onDeviceLoaded(HealthOverviewDeviceLoaded event, Emitter<HealthOverviewState> emit) {
    // Không để dữ liệu thiết bị ghi đè dữ liệu backend đã tải được.
    if (state.status == HealthOverviewStatus.success &&
        state.overview != null &&
        !_isDeviceOverview(state.overview!)) {
      return;
    }
    emit(state.copyWith(status: HealthOverviewStatus.success, overview: event.overview));
  }

  void _onManualPatched(HealthOverviewManualPatched event, Emitter<HealthOverviewState> emit) {
    final current = state.overview ?? HealthOverview.empty();
    emit(state.copyWith(
      status: HealthOverviewStatus.success,
      overview: current.copyWith(
        heartRate: event.heartRate ?? current.heartRate,
        bloodPressure: event.bloodPressure ?? current.bloodPressure,
      ),
    ));
  }

  /// Phân biệt nguồn dữ liệu qua `userId`: bản dựng từ thiết bị trong
  /// [DeviceHealthCubit.deviceHealthOverview] luôn đặt `userId: ''`, còn bản từ backend
  /// luôn mang userId thật. Đây là hợp đồng ngầm giữa hai lớp — sửa một bên thì phải
  /// sửa bên kia, nếu không dữ liệu backend sẽ bị device ghi đè.
  bool _isDeviceOverview(HealthOverview o) =>
      (o.heartRate?.userId.isEmpty ?? false) ||
      (o.weight?.userId.isEmpty ?? false) ||
      (o.bloodPressure?.userId.isEmpty ?? false) ||
      (o.temperature?.userId.isEmpty ?? false);

  @override
  Future<void> close() {
    _deviceSub?.cancel();
    return super.close();
  }
}
