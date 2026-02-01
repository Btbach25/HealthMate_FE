import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../../../data/services/device_health_service.dart';
import '../../../data/services/device_health_exporter.dart';

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
  final DeviceHealthExporter _exporter = DeviceHealthExporter();
  DeviceHealthCubit(this._service) : super(const DeviceHealthState());

  Future<void> poll() async {
    emit(state.copyWith(loading: true, error: null));
    // Thử xin quyền thủ công nếu chưa xin
    final ok = await _service.requestPermissionsManually();
    if (!ok) {
      debugPrint('[Health] Quyền Health Connect chưa được cấp. Vui lòng mở Health Connect và cấp quyền.');
    }
    // Lấy tối đa lịch sử 10 năm để khảo sát (nếu nền tảng cho phép)
    final result = await _service.fetchAllAndLog(
      startTime: DateTime.now().subtract(const Duration(days: 3650)),
    );
    if (result == null) {
      debugPrint('[Health] Không thể lấy dữ liệu thiết bị (chưa cấp quyền hoặc Health Connect chưa sẵn sàng).');
      emit(state.copyWith(loading: false, error: 'Không lấy được dữ liệu thiết bị'));
      return;
    }
    // Save to JSON file locally (desktop builds)
    final ts = DateTime.now();
    final stamp = '${ts.year}${ts.month.toString().padLeft(2,'0')}${ts.day.toString().padLeft(2,'0')}_${ts.hour.toString().padLeft(2,'0')}${ts.minute.toString().padLeft(2,'0')}${ts.second.toString().padLeft(2,'0')}';
    await _exporter.saveResultAsJson(result, fileName: 'health_sync_$stamp.json');

    // In ra terminal một số thông tin sức khỏe mỗi lần reload
    final points = result.dataPoints;
    final steps = points.where((p) => p.type == HealthDataType.STEPS).length;
    final hr = points.where((p) => p.type == HealthDataType.HEART_RATE).length;
    final sleepTypes = {
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_AWAKE,
    };
    final sleep = points.where((p) => sleepTypes.contains(p.type)).length;

    // In vài bản ghi tiêu biểu
    debugPrint('[Health] Reload @ ${result.fetchedAt.toIso8601String()}');
    debugPrint('  totalStepsToday: ${result.totalSteps}');
    debugPrint('  points: ${points.length} | steps: $steps | heartRate: $hr | sleep: $sleep');
    for (final p in points.take(10)) {
      debugPrint('  - ${p.type.name} ${p.value} ${p.unit.name} ${p.dateFrom.toIso8601String()}');
    }
    emit(state.copyWith(
      loading: false,
      lastUpdated: result.fetchedAt,
      totalSteps: result.totalSteps,
      dataCount: result.dataPoints.length,
      error: null,
    ));
  }
}
