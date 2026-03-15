import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../data/services/device_health_service.dart';
import '../../../data/services/health_ws_service.dart';

class DeviceHealthState extends Equatable {
  final bool loading;
  final DateTime? lastUpdated;
  final int? totalSteps;
  final int dataCount;
  final String? error;

  const DeviceHealthState({
    this.loading = false,
    this.lastUpdated,
    this.totalSteps,
    this.dataCount = 0,
    this.error,
  });

  DeviceHealthState copyWith({
    bool? loading,
    DateTime? lastUpdated,
    int? totalSteps,
    int? dataCount,
    String? error,
  }) => DeviceHealthState(
    loading: loading ?? this.loading,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    totalSteps: totalSteps ?? this.totalSteps,
    dataCount: dataCount ?? this.dataCount,
    error: error,
  );

  @override
  List<Object?> get props => [loading, lastUpdated, totalSteps, dataCount, error];
}

class DeviceHealthCubit extends Cubit<DeviceHealthState> {
  final DeviceHealthService _service;
  final HealthWsService _wsService;

  DeviceHealthCubit(this._service, this._wsService)
      : super(const DeviceHealthState());

  Future<void> poll() async {
    emit(state.copyWith(loading: true, error: null));
    final result = await _service.fetchAll();
    if (result == null) {
      emit(state.copyWith(
        loading: false,
        error: 'Không lấy được dữ liệu thiết bị',
      ));
      return;
    }

    emit(state.copyWith(
      loading: false,
      lastUpdated: result.fetchedAt,
      totalSteps: result.totalSteps,
      dataCount: result.dataPoints.length,
      error: null,
    ));

    // Upload lên BE trong background, không block UI
    _wsService.uploadDataPoints(result.dataPoints).catchError((e) {
      debugPrint('[DeviceHealthCubit] WS upload failed: $e');
    });
  }
}
