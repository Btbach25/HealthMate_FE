import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../../../data/services/device_health_service.dart';
import '../../../data/services/health_ws_service.dart';
import '../../../data/services/readiness_service.dart';
import '../../../data/models/health/health_overview.dart';
import '../../../data/models/health/heart_rate.dart';
import '../../../data/models/health/blood_pressure.dart';
import '../../../data/models/health/weight.dart';
import '../../../data/models/health/temperature.dart';

class DeviceHealthState extends Equatable {
  final bool loading;
  final DateTime? lastUpdated;
  final int? totalSteps;
  final int dataCount;
  final double? readinessScore;
  final bool readinessLoading;
  final double? bloodOxygen;
  final double? sleepHours;
  final String? error;
  // null = chưa kiểm tra / không áp dụng (non-Android)
  final bool? isHealthConnectConnected;

  const DeviceHealthState({
    this.loading = false,
    this.lastUpdated,
    this.totalSteps,
    this.dataCount = 0,
    this.readinessScore,
    this.readinessLoading = false,
    this.bloodOxygen,
    this.sleepHours,
    this.error,
    this.isHealthConnectConnected,
  });

  DeviceHealthState copyWith({
    bool? loading,
    DateTime? lastUpdated,
    int? totalSteps,
    int? dataCount,
    double? readinessScore,
    bool? readinessLoading,
    double? bloodOxygen,
    double? sleepHours,
    String? error,
    bool? isHealthConnectConnected,
  }) => DeviceHealthState(
    loading: loading ?? this.loading,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    totalSteps: totalSteps ?? this.totalSteps,
    dataCount: dataCount ?? this.dataCount,
    readinessScore: readinessScore ?? this.readinessScore,
    readinessLoading: readinessLoading ?? this.readinessLoading,
    bloodOxygen: bloodOxygen ?? this.bloodOxygen,
    sleepHours: sleepHours ?? this.sleepHours,
    error: error,
    isHealthConnectConnected: isHealthConnectConnected ?? this.isHealthConnectConnected,
  );

  @override
  List<Object?> get props =>
      [loading, lastUpdated, totalSteps, dataCount, readinessScore, readinessLoading, bloodOxygen, sleepHours, error, isHealthConnectConnected];
}

class DeviceHealthCubit extends Cubit<DeviceHealthState> {
  final DeviceHealthService _service;
  final HealthWsService _wsService;
  final ReadinessService _readinessService;

  Timer? _syncTimer;
  Timer? _fetchTimer;
  List<HealthDataPoint> _lastPoints = [];
  // Ngăn emit sau khi logout — DeviceHealthCubit sống ở app-level (không bị close),
  // nên cần flag thủ công để bảo vệ BlocBuilder trong shell đang bị dispose.
  bool _stopped = false;

  List<HealthDataPoint> get lastPoints => List.unmodifiable(_lastPoints);

  /// Convert local Health Connect data → HealthOverview (dùng khi BE không có).
  HealthOverview? get deviceHealthOverview {
    if (_lastPoints.isEmpty) return null;
    final now = DateTime.now();
    final hr = _latestNumeric(_lastPoints, HealthDataType.HEART_RATE);
    final sys = _latestNumeric(_lastPoints, HealthDataType.BLOOD_PRESSURE_SYSTOLIC);
    final dia = _latestNumeric(_lastPoints, HealthDataType.BLOOD_PRESSURE_DIASTOLIC);
    final wt = _latestNumeric(_lastPoints, HealthDataType.WEIGHT);
    final temp = _latestNumeric(_lastPoints, HealthDataType.BODY_TEMPERATURE);
    final spo2 = _latestNumeric(_lastPoints, HealthDataType.BLOOD_OXYGEN);
    return HealthOverview(
      heartRate: hr != null ? HeartRate(time: now, userId: '', value: hr) : null,
      bloodPressure: (sys != null || dia != null)
          ? BloodPressure(time: now, userId: '', systolic: sys?.toInt(), diastolic: dia?.toInt())
          : null,
      weight: wt != null ? Weight(time: now, userId: '', value: wt) : null,
      temperature: temp != null ? Temperature(time: now, userId: '', value: temp) : null,
      bloodOxygen: spo2,
    );
  }

  DeviceHealthCubit(this._service, this._wsService, this._readinessService)
      : super(const DeviceHealthState());

  /// Fetch device health 1 lần + tính readiness.
  Future<void> poll() async {
    _stopped = false; // reset khi user đang active
    final onAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    emit(state.copyWith(loading: true, error: null));
    final result = await _service.fetchAll();
    if (result == null) {
      emit(state.copyWith(
        loading: false,
        error: 'Không lấy được dữ liệu thiết bị',
        isHealthConnectConnected: onAndroid ? false : null,
      ));
      return;
    }

    _lastPoints = result.dataPoints;

    // 0 điểm + không có steps trên Android = coi như chưa kết nối được HC
    final hcConnected = onAndroid
        ? (result.dataPoints.isNotEmpty || result.totalSteps != null)
        : null;

    emit(state.copyWith(
      loading: false,
      lastUpdated: result.fetchedAt,
      totalSteps: result.totalSteps,
      dataCount: result.dataPoints.length,
      readinessLoading: true,
      error: null,
      isHealthConnectConnected: hcConnected,
    ));

    // Kết nối WS (nếu chưa) và gửi ngay lần đầu
    _wsService.connect().then((_) {
      _wsService.sendLatestMetrics(_lastPoints);
    }).catchError((e) {
      debugPrint('[DeviceHealthCubit] WS connect error: $e');
    });

    _fetchReadiness(result);
  }

  /// Bắt đầu gửi dữ liệu lên BE mỗi 5 giây qua WebSocket
  /// và re-fetch Health Connect mỗi 60 giây để lấy data mới từ Samsung Health.
  void startPeriodicSync() {
    if (kIsWeb) return;
    _syncTimer?.cancel();
    _fetchTimer?.cancel();

    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_lastPoints.isNotEmpty) {
        _wsService.sendLatestMetrics(_lastPoints).catchError((e) {
          debugPrint('[DeviceHealthCubit] Periodic sync error: $e');
        });
      }
    });

    _fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final result = await _service.fetchAll();
      if (result == null) return;
      _lastPoints = result.dataPoints;
      emit(state.copyWith(
        lastUpdated: result.fetchedAt,
        totalSteps: result.totalSteps,
        dataCount: result.dataPoints.length,
      ));
      _wsService.sendLatestMetrics(_lastPoints).catchError((e) {
        debugPrint('[DeviceHealthCubit] Fetch-timer sync error: $e');
      });
    });

    debugPrint('[DeviceHealthCubit] Periodic sync started (WS:5s, HC-fetch:5s)');
  }

  /// Cập nhật ngay SpO2 trong state (sau khi nhập tay thành công).
  void patchBloodOxygen(double value) {
    if (!_stopped) emit(state.copyWith(bloodOxygen: value));
  }

  /// Cập nhật ngay số bước trong state (sau khi nhập tay thành công).
  void patchTotalSteps(int steps) {
    if (!_stopped) {
      emit(state.copyWith(totalSteps: steps, lastUpdated: DateTime.now()));
    }
  }

  /// Gửi một chỉ số nhập tay lên BE. Trả về true nếu gửi thành công.
  Future<bool> pushManualMetric(String metricType, double value) async {
    if (kIsWeb) return false;
    try {
      if (!_stopped) await _wsService.connect();
      await _wsService.sendManualMetric(metricType, value);
      return true;
    } catch (e) {
      debugPrint('[DeviceHealthCubit] pushManualMetric error: $e');
      return false;
    }
  }

  /// Dừng gửi định kỳ và đóng WS.
  void stopPeriodicSync() {
    _stopped = true; // chặn emit từ async ops đang bay (vd: _fetchReadiness)
    _syncTimer?.cancel();
    _syncTimer = null;
    _fetchTimer?.cancel();
    _fetchTimer = null;
    _wsService.disconnect();
    debugPrint('[DeviceHealthCubit] Periodic sync stopped');
  }

  Future<void> _fetchReadiness(DeviceHealthResult result) async {
    final points = result.dataPoints;

    final heartRate = _latestNumeric(points, HealthDataType.HEART_RATE);
    final bloodOxygen = _latestNumeric(points, HealthDataType.BLOOD_OXYGEN);
    final sleepHours = _totalSleepHours(points);

    if (heartRate == null || _stopped) {
      if (!_stopped) {
        emit(state.copyWith(
          readinessLoading: false,
          bloodOxygen: bloodOxygen,
          sleepHours: sleepHours > 0 ? sleepHours : null,
        ));
      }
      return;
    }

    final calories = _totalCalories(points);
    final steps = result.totalSteps?.toDouble();

    debugPrint('[Readiness] Input → HR=$heartRate, SpO2=${bloodOxygen ?? 98.0}, sleep=${sleepHours.toStringAsFixed(2)}h, steps=$steps, cal=$calories');

    var score = await _readinessService.getScore(
      heartRate: heartRate,
      sleepDuration: sleepHours,
      stressLevel: 'Low',
      bloodOxygen: bloodOxygen ?? 98.0,
      steps: steps,
      caloriesBurned: calories,
    );

    // Nếu đã logout trong lúc await → không emit, tránh crash BlocBuilder trong shell
    if (_stopped) return;

    if (score != null) {
      debugPrint('[Readiness] Source=BE score=$score');
    } else {
      // Tính điểm cục bộ nếu BE không trả về
      score = _computeLocalScore(
        heartRate: heartRate,
        sleepHours: sleepHours,
        steps: steps,
        bloodOxygen: bloodOxygen,
      );
      debugPrint('[Readiness] Source=LOCAL score=$score (HR=$heartRate → hrScore=${((40 - ((heartRate - 75).abs() / 25 * 40)).clamp(0, 40)).toStringAsFixed(1)}, sleep=${(sleepHours / 8 * 30).clamp(0, 30).toStringAsFixed(1)}, steps=${steps != null ? (steps / 10000 * 20).clamp(0, 20).toStringAsFixed(1) : "10.0(default)"}, spo2=${bloodOxygen != null ? (bloodOxygen >= 95 ? "10.0" : (bloodOxygen / 95 * 10).clamp(0, 10).toStringAsFixed(1)) : "8.0(default)"})');
    }

    emit(state.copyWith(
      readinessScore: score,
      readinessLoading: false,
      bloodOxygen: bloodOxygen,
      sleepHours: sleepHours > 0 ? sleepHours : null,
    ));
  }

  @override
  Future<void> close() {
    stopPeriodicSync();
    return super.close();
  }

  // ── Helpers ──────────────────────────────────────────────

  double? _latestNumeric(List<HealthDataPoint> points, HealthDataType type) {
    final filtered = points.where((p) => p.type == type).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
    final value = filtered.first.value;
    if (value is NumericHealthValue) return value.numericValue.toDouble();
    return null;
  }

  double _totalSleepHours(List<HealthDataPoint> points) {
    final sleepTypes = {
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
    };
    double totalMinutes = 0;
    for (final p in points.where((p) => sleepTypes.contains(p.type))) {
      totalMinutes += p.dateTo.difference(p.dateFrom).inMinutes;
    }
    return totalMinutes / 60;
  }

  double _computeLocalScore({
    required double heartRate,
    required double sleepHours,
    double? steps,
    double? bloodOxygen,
  }) {
    // HR: 60-100 bpm tốt → 40đ, penalize ngoài range
    final hrDiff = (heartRate - 75).abs();
    final hrScore = (40 - (hrDiff / 25 * 40)).clamp(0, 40).toDouble();
    // Sleep: 7-9h → 30đ
    final sleepScore = (sleepHours / 8 * 30).clamp(0, 30).toDouble();
    // Steps: 10000 → 20đ
    final stepsScore = steps != null ? (steps / 10000 * 20).clamp(0, 20).toDouble() : 10.0;
    // SpO2: ≥95 → 10đ
    final spo2Score = bloodOxygen != null ? (bloodOxygen >= 95 ? 10.0 : (bloodOxygen / 95 * 10).clamp(0, 10).toDouble()) : 8.0;
    return hrScore + sleepScore + stepsScore + spo2Score;
  }

  double? _totalCalories(List<HealthDataPoint> points) {
    double total = 0;
    bool found = false;
    for (final p in points.where((p) => p.type == HealthDataType.ACTIVE_ENERGY_BURNED)) {
      final v = p.value;
      if (v is NumericHealthValue) {
        total += v.numericValue.toDouble();
        found = true;
      }
    }
    return found ? total : null;
  }
}
