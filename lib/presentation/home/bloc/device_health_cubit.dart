import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fe/data/models/health/blood_pressure.dart';
import 'package:fe/data/models/health/health_overview.dart';
import 'package:fe/data/models/health/heart_rate.dart';
import 'package:fe/data/models/health/stress_prediction.dart';
import 'package:fe/data/models/health/temperature.dart';
import 'package:fe/data/models/health/weight.dart';
import 'package:fe/data/services/device_health_service.dart';
import 'package:fe/data/services/health_ws_service.dart';
import 'package:fe/data/services/readiness_service.dart';
import 'package:fe/data/services/stress_service.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Ảnh chụp dữ liệu sức khoẻ đọc từ thiết bị, cộng với kết quả của hai API suy luận
/// (readiness và stress) chạy trên dữ liệu đó.
///
/// Ba nhóm cờ loading tách biệt vì chúng hoàn tất ở các thời điểm khác nhau:
/// [loading] cho lần đọc Health Connect/HealthKit, [readinessLoading] và
/// [stressLoading] cho hai lời gọi API chạy song song sau đó.
///
/// Cạm bẫy của [copyWith]: chỉ riêng [error] là gán thẳng (nên truyền error: null
/// sẽ xoá được lỗi); mọi trường còn lại dùng toán tử ?? nên không thể đặt lại về null.
/// Đây là chủ ý — dữ liệu cũ vẫn hiển thị được khi vòng đọc mới chưa có số liệu.
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

  /// Chỉ có nghĩa trên Android, nơi ứng dụng bắt buộc phải đi qua Health Connect.
  /// null = chưa kiểm tra, hoặc nền tảng không áp dụng (iOS/web).
  final bool? isHealthConnectConnected;
  final StressPrediction? stressPrediction;
  final bool stressLoading;
  final bool stressDataEstimated;
  final bool stressApiError;

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
    this.stressPrediction,
    this.stressLoading = false,
    this.stressDataEstimated = false,
    this.stressApiError = false,
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
    StressPrediction? stressPrediction,
    bool? stressLoading,
    bool? stressDataEstimated,
    bool? stressApiError,
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
    isHealthConnectConnected:
        isHealthConnectConnected ?? this.isHealthConnectConnected,
    stressPrediction: stressPrediction ?? this.stressPrediction,
    stressLoading: stressLoading ?? this.stressLoading,
    stressDataEstimated: stressDataEstimated ?? this.stressDataEstimated,
    stressApiError: stressApiError ?? this.stressApiError,
  );

  @override
  List<Object?> get props => [
    loading,
    lastUpdated,
    totalSteps,
    dataCount,
    readinessScore,
    readinessLoading,
    bloodOxygen,
    sleepHours,
    error,
    isHealthConnectConnected,
    stressPrediction,
    stressLoading,
    stressDataEstimated,
    stressApiError,
  ];
}

/// Nguồn dữ liệu sức khoẻ đọc từ thiết bị (Health Connect trên Android, HealthKit
/// trên iOS) và là cầu nối đẩy dữ liệu đó lên backend qua WebSocket.
///
/// Cubit này được provide ở app-level (xem lib/app.dart) chứ không theo màn hình,
/// vì việc đồng bộ phải sống xuyên suốt các tab.
///
/// Luồng state:
///
///   [poll]  -> loading=true
///           -> đọc thiết bị thất bại -> loading=false, error != null,
///              isHealthConnectConnected=false (chỉ trên Android)
///           -> đọc thành công        -> loading=false, cập nhật dataCount/totalSteps/
///              lastUpdated, readinessLoading=true, stressLoading=true; sau đó hai
///              nhánh async độc lập [_fetchReadiness] và [_fetchStress] lần lượt hạ
///              cờ loading tương ứng của mình.
///
///   [startPeriodicSync] -> dựng hai Timer nền, mỗi lần chạy chỉ cập nhật
///                          dataCount/totalSteps/lastUpdated (không đụng readiness/stress).
///   [stopPeriodicSync]  -> huỷ Timer, đóng WebSocket, bật cờ chặn emit.
///
/// Ai gọi:
/// - [HomeView] gọi [poll] + [startPeriodicSync] khi vào tab Tổng quan và
///   [stopPeriodicSync] khi rời đi.
/// - lib/app.dart gọi [stopPeriodicSync] khi người dùng đăng xuất.
/// - StatsBloc và stats_view.dart đọc state làm dữ liệu dự phòng khi API thống kê lỗi.
/// - Dialog nhập tay trong widgets/metric_carousel.dart gọi [pushManualMetric],
///   [patchBloodOxygen], [patchTotalSteps].
///
/// Ai nghe: [HealthOverviewBloc] subscribe [stream] để lấy số liệu thiết bị làm nguồn
/// dự phòng khi backend chưa có dữ liệu.
class DeviceHealthCubit extends Cubit<DeviceHealthState> {
  final DeviceHealthService _service;
  final HealthWsService _wsService;
  final ReadinessService _readinessService;
  final StressService _stressService;

  Timer? _syncTimer;
  Timer? _fetchTimer;
  List<HealthDataPoint> _lastPoints = [];
  // Ngăn emit sau khi logout. Cubit sống ở app-level nên không bao giờ được close(),
  // do đó isClosed luôn false và không bảo vệ được gì; cần cờ thủ công để các tác vụ
  // async đang bay (readiness/stress) không emit vào lúc shell đang bị dispose.
  bool _stopped = false;

  List<HealthDataPoint> get lastPoints => List.unmodifiable(_lastPoints);

  /// Dựng [HealthOverview] từ dữ liệu thiết bị, dùng làm nguồn dự phòng khi backend
  /// chưa có số liệu.
  ///
  /// Hợp đồng quan trọng: mọi bản ghi ở đây đều đặt userId rỗng. Đó chính là dấu hiệu
  /// [HealthOverviewBloc] dùng để nhận ra "đây là dữ liệu thiết bị" và cho phép dữ liệu
  /// backend ghi đè lên. Đừng điền userId thật vào đây.
  HealthOverview? get deviceHealthOverview {
    if (_lastPoints.isEmpty) return null;
    final now = DateTime.now();
    final hr = _latestNumeric(_lastPoints, HealthDataType.HEART_RATE);
    final sys = _latestNumeric(
      _lastPoints,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    );
    final dia = _latestNumeric(
      _lastPoints,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    );
    final wt = _latestNumeric(_lastPoints, HealthDataType.WEIGHT);
    final temp = _latestNumeric(_lastPoints, HealthDataType.BODY_TEMPERATURE);
    final spo2 = _latestNumeric(_lastPoints, HealthDataType.BLOOD_OXYGEN);
    return HealthOverview(
      heartRate: hr != null
          ? HeartRate(time: now, userId: '', value: hr)
          : null,
      bloodPressure: (sys != null || dia != null)
          ? BloodPressure(
              time: now,
              userId: '',
              systolic: sys?.toInt(),
              diastolic: dia?.toInt(),
            )
          : null,
      weight: wt != null ? Weight(time: now, userId: '', value: wt) : null,
      temperature: temp != null
          ? Temperature(time: now, userId: '', value: temp)
          : null,
      bloodOxygen: spo2,
    );
  }

  DeviceHealthCubit(
    this._service,
    this._wsService,
    this._readinessService,
    this._stressService,
  ) : super(const DeviceHealthState());

  /// Đọc dữ liệu thiết bị một lần, rồi kích hoạt tính readiness và stress.
  ///
  /// Gọi lại [poll] cũng đồng thời bỏ cờ chặn emit mà [stopPeriodicSync] đã đặt trước
  /// đó, nên đây là điểm "hồi sinh" cubit sau khi người dùng rời màn hình rồi quay lại.
  Future<void> poll() async {
    _stopped = false; // người dùng active trở lại → cho phép emit
    final onAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    emit(state.copyWith(loading: true, error: null));
    final result = await _service.fetchAll();
    if (result == null) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Không lấy được dữ liệu thiết bị',
          isHealthConnectConnected: onAndroid ? false : null,
        ),
      );
      return;
    }

    _lastPoints = result.dataPoints;

    // Android không có API nào cho biết "đã cấp quyền Health Connect chưa" một cách
    // đáng tin, nên phải suy luận gián tiếp: đọc được 0 điểm dữ liệu và cũng không có
    // số bước thì gần như chắc chắn là chưa kết nối/chưa cấp quyền. iOS không cần
    // suy luận này nên để null.
    final hcConnected = onAndroid
        ? (result.dataPoints.isNotEmpty || result.totalSteps != null)
        : null;

    emit(
      state.copyWith(
        loading: false,
        lastUpdated: result.fetchedAt,
        totalSteps: result.totalSteps,
        dataCount: result.dataPoints.length,
        readinessLoading: true,
        stressLoading: true,
        error: null,
        isHealthConnectConnected: hcConnected,
      ),
    );

    // Cố ý không await: màn hình không được chờ WebSocket bắt tay xong mới hiện số liệu.
    _wsService
        .connect()
        .then((_) {
          _wsService.sendLatestMetrics(_lastPoints);
        })
        .catchError((e) {
          debugPrint('[DeviceHealthCubit] WS connect error: $e');
        });

    _fetchReadiness(result);
    _fetchStress(result);
  }

  /// Bật hai Timer nền: đẩy chỉ số mới nhất lên backend qua WebSocket mỗi 5 giây,
  /// và đọc lại Health Connect cũng mỗi 5 giây.
  ///
  /// Nhịp 5 giây là vì Samsung Health ghi vào Health Connect theo lô và có độ trễ;
  /// đọc thưa hơn thì biểu đồ nhịp tim trực tiếp bị giật. Hai Timer tách riêng để một
  /// lần đọc thiết bị thất bại không làm gián đoạn việc đẩy WebSocket.
  ///
  /// Chỉ cập nhật dataCount/totalSteps/lastUpdated — cố ý không gọi lại readiness và
  /// stress; hai API đó tốn kém và do [poll] lo (xem HomeView._startPolling).
  ///
  /// Không có tác dụng trên web vì ở đó không tồn tại Health Connect/HealthKit.
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
      emit(
        state.copyWith(
          lastUpdated: result.fetchedAt,
          totalSteps: result.totalSteps,
          dataCount: result.dataPoints.length,
        ),
      );
      _wsService.sendLatestMetrics(_lastPoints).catchError((e) {
        debugPrint('[DeviceHealthCubit] Fetch-timer sync error: $e');
      });
    });

    debugPrint(
      '[DeviceHealthCubit] Periodic sync started (WS:5s, HC-fetch:5s)',
    );
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

  /// Gửi một chỉ số người dùng nhập tay lên backend qua WebSocket.
  ///
  /// [metricType] phải khớp khoá backend quy ước (heart_rate, blood_pressure, spo2,
  /// steps_count — xem các hằng _k* trong widgets/metric_carousel.dart).
  /// Trả về false thay vì ném lỗi, để phía gọi hiện snackbar mà không cần try/catch.
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

  /// Dừng đồng bộ định kỳ, đóng WebSocket và chặn mọi emit về sau.
  ///
  /// Phải gọi khi rời màn hình hoặc khi đăng xuất: cubit không bị close nên nếu không
  /// chặn, một [_fetchReadiness] đang bay có thể emit vào lúc widget tree đã đổi.
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
        emit(
          state.copyWith(
            readinessLoading: false,
            bloodOxygen: bloodOxygen,
            sleepHours: sleepHours > 0 ? sleepHours : null,
          ),
        );
      }
      return;
    }

    final calories = _totalCalories(points);
    final steps = result.totalSteps?.toDouble();

    debugPrint(
      '[Readiness] Input → HR=$heartRate, SpO2=${bloodOxygen ?? 98.0}, sleep=${sleepHours.toStringAsFixed(2)}h, steps=$steps, cal=$calories',
    );

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
      // Backend không trả về (lỗi mạng hoặc chưa deploy) thì tính cục bộ, để người dùng
      // luôn thấy một điểm số thay vì ô trống.
      score = _computeLocalScore(
        heartRate: heartRate,
        sleepHours: sleepHours,
        steps: steps,
        bloodOxygen: bloodOxygen,
      );
      debugPrint(
        '[Readiness] Source=LOCAL score=$score (HR=$heartRate → hrScore=${((40 - ((heartRate - 75).abs() / 25 * 40)).clamp(0, 40)).toStringAsFixed(1)}, sleep=${(sleepHours / 8 * 30).clamp(0, 30).toStringAsFixed(1)}, steps=${steps != null ? (steps / 10000 * 20).clamp(0, 20).toStringAsFixed(1) : "10.0(default)"}, spo2=${bloodOxygen != null ? (bloodOxygen >= 95 ? "10.0" : (bloodOxygen / 95 * 10).clamp(0, 10).toStringAsFixed(1)) : "8.0(default)"})',
      );
    }

    emit(
      state.copyWith(
        readinessScore: score,
        readinessLoading: false,
        bloodOxygen: bloodOxygen,
        sleepHours: sleepHours > 0 ? sleepHours : null,
      ),
    );
  }

  Future<void> _fetchStress(DeviceHealthResult result) async {
    final points = result.dataPoints;

    final typeCount = <String, int>{};
    for (final p in points) {
      typeCount[p.type.name] = (typeCount[p.type.name] ?? 0) + 1;
    }
    debugPrint('[Stress] Total points: ${points.length}, types: $typeCount');

    final hrMeanStd = _hrMeanStd(points);
    final hrMean = hrMeanStd.$1;
    debugPrint(
      '[Stress] HR points found: ${points.where((p) => p.type == HealthDataType.HEART_RATE).length}, hrMean=$hrMean',
    );
    if (hrMean == 0 || _stopped) {
      debugPrint('[Stress] Skip — no HR data');
      if (!_stopped) emit(state.copyWith(stressLoading: false));
      return;
    }

    final rmssdRaw = _latestNumeric(
      points,
      HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    );
    debugPrint(
      '[Stress] RMSSD raw=$rmssdRaw, HRV points: ${points.where((p) => p.type == HealthDataType.HEART_RATE_VARIABILITY_RMSSD).length}',
    );
    // Chỉ thiết bị đeo cao cấp mới ghi HRV RMSSD. Khi thiếu, ước tính từ độ lệch chuẩn
    // nhịp tim: khác thang đo nhưng tương quan dương, đủ để mô hình xếp hạng. Kết quả
    // được đánh dấu qua stressDataEstimated để UI hạ mức tin cậy khi hiển thị.
    final hrStd = hrMeanStd.$2;
    final rmssd =
        rmssdRaw ?? (hrStd > 0 ? (hrStd * 3.0).clamp(5.0, 80.0) : 25.0);
    final isEstimated = rmssdRaw == null;

    final skinTemp =
        _latestNumeric(points, HealthDataType.SKIN_TEMPERATURE) ?? 33.0;

    debugPrint(
      '[Stress] Input → hrMean=$hrMean, hrStd=$hrStd, rmssd=$rmssd${isEstimated ? "(estimated)" : ""}, temp=$skinTemp',
    );

    final prediction = await _stressService.predict(
      hrMean: hrMean,
      hrStd: hrMeanStd.$2,
      rmssd: rmssd,
      tempMean: skinTemp,
    );

    if (_stopped) return;

    emit(
      state.copyWith(
        stressPrediction: prediction,
        stressLoading: false,
        stressDataEstimated: isEstimated,
        stressApiError: prediction == null,
      ),
    );
  }

  /// Trung bình và độ lệch chuẩn nhịp tim trong 60 giây gần nhất.
  ///
  /// Nếu cửa sổ 60 giây trống thì lùi về toàn bộ điểm dữ liệu có được — thà dùng số
  /// liệu cũ còn hơn không dự đoán được stress. Trả về (0, 0) khi hoàn toàn không có
  /// nhịp tim; phía gọi coi mean == 0 là "không có dữ liệu".
  (double, double) _hrMeanStd(List<HealthDataPoint> points) {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 60));
    var hrPoints = points
        .where(
          (p) =>
              p.type == HealthDataType.HEART_RATE && p.dateFrom.isAfter(cutoff),
        )
        .toList();
    if (hrPoints.isEmpty) {
      hrPoints = points
          .where((p) => p.type == HealthDataType.HEART_RATE)
          .toList();
    }
    if (hrPoints.isEmpty) return (0.0, 0.0);

    final values = hrPoints
        .map((p) => p.value)
        .whereType<NumericHealthValue>()
        .map((v) => v.numericValue.toDouble())
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) return (0.0, 0.0);
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (values.length == 1) return (mean, 0.0);
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        values.length;
    return (mean, math.sqrt(variance));
  }

  @override
  Future<void> close() {
    stopPeriodicSync();
    return super.close();
  }

  /// Giá trị số mới nhất của một [HealthDataType], hoặc null nếu không có điểm nào.
  ///
  /// Health Connect trả về dữ liệu không đảm bảo thứ tự thời gian nên phải tự sắp xếp,
  /// và bỏ qua các điểm không phải kiểu số (ví dụ bản ghi giấc ngủ).
  double? _latestNumeric(List<HealthDataPoint> points, HealthDataType type) {
    final filtered = points.where((p) => p.type == type).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
    final value = filtered.first.value;
    if (value is NumericHealthValue) return value.numericValue.toDouble();
    return null;
  }

  /// Tổng số giờ ngủ, tính bằng độ dài các đoạn ngủ chứ không phải một giá trị đo.
  ///
  /// Cộng cả ASLEEP, DEEP và REM. Health Connect ghi các giai đoạn này thành những đoạn
  /// riêng biệt, không chồng lấn, nên cộng thẳng là đúng.
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

  /// Công thức readiness dự phòng khi API không phản hồi.
  ///
  /// Thang 100 điểm chia theo trọng số: nhịp tim 40, giấc ngủ 30, số bước 20, SpO2 10.
  /// Thiếu số bước hoặc SpO2 thì dùng giá trị trung tính (10 và 8) thay vì 0, để dữ
  /// liệu khuyết không bị hiểu nhầm thành sức khoẻ kém.
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
    final stepsScore = steps != null
        ? (steps / 10000 * 20).clamp(0, 20).toDouble()
        : 10.0;
    // SpO2: ≥95 → 10đ
    final spo2Score = bloodOxygen != null
        ? (bloodOxygen >= 95
              ? 10.0
              : (bloodOxygen / 95 * 10).clamp(0, 10).toDouble())
        : 8.0;
    return hrScore + sleepScore + stepsScore + spo2Score;
  }

  /// Tổng năng lượng hoạt động đã đốt. Trả về null (chứ không phải 0) khi hoàn toàn
  /// không có bản ghi nào, để phân biệt "chưa có dữ liệu" với "chưa vận động".
  double? _totalCalories(List<HealthDataPoint> points) {
    double total = 0;
    bool found = false;
    for (final p in points.where(
      (p) => p.type == HealthDataType.ACTIVE_ENERGY_BURNED,
    )) {
      final v = p.value;
      if (v is NumericHealthValue) {
        total += v.numericValue.toDouble();
        found = true;
      }
    }
    return found ? total : null;
  }
}
