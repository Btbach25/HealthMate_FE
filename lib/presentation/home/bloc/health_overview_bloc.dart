import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/data/models/health/health_overview.dart';
import 'package:fe/data/repositories/health_repository.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';

part 'health_overview_event.dart';
part 'health_overview_state.dart';

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

    // Nếu device đã có data ngay từ đầu, dispatch luôn
    if (_deviceCubit.lastPoints.isNotEmpty) {
      final ov = _deviceCubit.deviceHealthOverview;
      if (ov != null) { add(HealthOverviewDeviceLoaded(ov)); }
    }

    // Subscribe stream để bắt khi data thay đổi
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
      // Nếu đã có device data, không hiển thị lỗi
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
    // Chỉ dùng device data nếu chưa có BE data
    if (state.status == HealthOverviewStatus.success &&
        state.overview != null &&
        !_isDeviceOverview(state.overview!)) {
      return;
    }
    emit(state.copyWith(status: HealthOverviewStatus.success, overview: event.overview));
  }

  /// BE overview có userId thực; device overview luôn có userId rỗng
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
