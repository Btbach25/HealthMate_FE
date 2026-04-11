import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Kết quả fetch tổng hợp từ Health Connect.
class HealthFetchResult {
  final List<HealthDataPoint> heartRate;
  final List<HealthDataPoint> restingHeartRate;
  final List<HealthDataPoint> steps;
  final List<HealthDataPoint> bloodOxygen;
  final List<HealthDataPoint> bloodPressureSystolic;
  final List<HealthDataPoint> bloodPressureDiastolic;
  final List<HealthDataPoint> weight;
  final List<HealthDataPoint> height;
  final List<HealthDataPoint> activeEnergyBurned;
  final List<HealthDataPoint> sleepAsleep;
  final List<HealthDataPoint> sleepAwake;
  final List<HealthDataPoint> sleepDeep;
  final List<HealthDataPoint> sleepRem;
  final List<HealthDataPoint> bodyTemperature;
  final List<HealthDataPoint> respiratoryRate;
  final List<HealthDataPoint> bloodGlucose;
  final List<HealthDataPoint> workout;
  final List<HealthDataPoint> distanceDelta;
  final int? stepsToday;
  final DateTime fetchedAt;

  const HealthFetchResult({
    this.heartRate = const [],
    this.restingHeartRate = const [],
    this.steps = const [],
    this.bloodOxygen = const [],
    this.bloodPressureSystolic = const [],
    this.bloodPressureDiastolic = const [],
    this.weight = const [],
    this.height = const [],
    this.activeEnergyBurned = const [],
    this.sleepAsleep = const [],
    this.sleepAwake = const [],
    this.sleepDeep = const [],
    this.sleepRem = const [],
    this.bodyTemperature = const [],
    this.respiratoryRate = const [],
    this.bloodGlucose = const [],
    this.workout = const [],
    this.distanceDelta = const [],
    this.stepsToday,
    required this.fetchedAt,
  });

  /// Tất cả điểm dữ liệu gộp lại (dùng cho DeviceStatsConverter).
  List<HealthDataPoint> get all => [
    ...heartRate,
    ...restingHeartRate,
    ...steps,
    ...bloodOxygen,
    ...bloodPressureSystolic,
    ...bloodPressureDiastolic,
    ...weight,
    ...height,
    ...activeEnergyBurned,
    ...sleepAsleep,
    ...sleepAwake,
    ...sleepDeep,
    ...sleepRem,
    ...bodyTemperature,
    ...respiratoryRate,
    ...bloodGlucose,
    ...workout,
    ...distanceDelta,
  ];

  int get totalPoints => all.length;
}

/// Fetch dữ liệu sức khỏe từ Health Connect theo từng loại.
/// Nhận [hoursBack] để lấy dữ liệu trong khoảng giờ tính từ hiện tại.
class HealthDataFetcher {
  final Health _health;

  HealthDataFetcher(this._health);

  DateTime _start(int hoursBack) =>
      DateTime.now().subtract(Duration(hours: hoursBack));

  // ─── Hàm con theo từng loại ─────────────────────────────────────────────

  Future<List<HealthDataPoint>> fetchHeartRate({int hoursBack = 168}) =>
      _fetch(HealthDataType.HEART_RATE, hoursBack);

  Future<List<HealthDataPoint>> fetchRestingHeartRate({int hoursBack = 168}) =>
      _fetch(HealthDataType.RESTING_HEART_RATE, hoursBack);

  Future<List<HealthDataPoint>> fetchSteps({int hoursBack = 168}) =>
      _fetch(HealthDataType.STEPS, hoursBack);

  Future<List<HealthDataPoint>> fetchBloodOxygen({int hoursBack = 168}) =>
      _fetch(HealthDataType.BLOOD_OXYGEN, hoursBack);

  Future<List<HealthDataPoint>> fetchBloodPressureSystolic({
    int hoursBack = 168,
  }) => _fetch(HealthDataType.BLOOD_PRESSURE_SYSTOLIC, hoursBack);

  Future<List<HealthDataPoint>> fetchBloodPressureDiastolic({
    int hoursBack = 168,
  }) => _fetch(HealthDataType.BLOOD_PRESSURE_DIASTOLIC, hoursBack);

  Future<List<HealthDataPoint>> fetchWeight({int hoursBack = 720}) =>
      _fetch(HealthDataType.WEIGHT, hoursBack);

  Future<List<HealthDataPoint>> fetchHeight({int hoursBack = 720}) =>
      _fetch(HealthDataType.HEIGHT, hoursBack);

  Future<List<HealthDataPoint>> fetchActiveEnergyBurned({
    int hoursBack = 168,
  }) => _fetch(HealthDataType.ACTIVE_ENERGY_BURNED, hoursBack);

  Future<List<HealthDataPoint>> fetchSleepAsleep({int hoursBack = 168}) =>
      _fetch(HealthDataType.SLEEP_ASLEEP, hoursBack);

  Future<List<HealthDataPoint>> fetchSleepAwake({int hoursBack = 168}) =>
      _fetch(HealthDataType.SLEEP_AWAKE, hoursBack);

  Future<List<HealthDataPoint>> fetchSleepDeep({int hoursBack = 168}) =>
      _fetch(HealthDataType.SLEEP_DEEP, hoursBack);

  Future<List<HealthDataPoint>> fetchSleepRem({int hoursBack = 168}) =>
      _fetch(HealthDataType.SLEEP_REM, hoursBack);

  Future<List<HealthDataPoint>> fetchBodyTemperature({int hoursBack = 168}) =>
      _fetch(HealthDataType.BODY_TEMPERATURE, hoursBack);

  Future<List<HealthDataPoint>> fetchRespiratoryRate({int hoursBack = 168}) =>
      _fetch(HealthDataType.RESPIRATORY_RATE, hoursBack);

  Future<List<HealthDataPoint>> fetchBloodGlucose({int hoursBack = 168}) =>
      _fetch(HealthDataType.BLOOD_GLUCOSE, hoursBack);

  Future<List<HealthDataPoint>> fetchWorkout({int hoursBack = 168}) =>
      _fetch(HealthDataType.WORKOUT, hoursBack);

  Future<List<HealthDataPoint>> fetchDistanceDelta({int hoursBack = 168}) =>
      _fetch(HealthDataType.DISTANCE_DELTA, hoursBack);

  // ─── Hàm tổng ───────────────────────────────────────────────────────────

  /// Lấy toàn bộ dữ liệu trong [hoursBack] giờ qua.
  /// Gọi song song tất cả hàm con rồi tổng hợp kết quả.
  Future<HealthFetchResult> fetchAll({int hoursBack = 720}) async {
    final now = DateTime.now();

    final results = await Future.wait([
      fetchHeartRate(hoursBack: hoursBack),
      fetchRestingHeartRate(hoursBack: hoursBack),
      fetchSteps(hoursBack: hoursBack),
      fetchBloodOxygen(hoursBack: hoursBack),
      fetchBloodPressureSystolic(hoursBack: hoursBack),
      fetchBloodPressureDiastolic(hoursBack: hoursBack),
      fetchWeight(hoursBack: hoursBack),
      fetchHeight(hoursBack: hoursBack),
      fetchActiveEnergyBurned(hoursBack: hoursBack),
      fetchSleepAsleep(hoursBack: hoursBack),
      fetchSleepAwake(hoursBack: hoursBack),
      fetchSleepDeep(hoursBack: hoursBack),
      fetchSleepRem(hoursBack: hoursBack),
      fetchBodyTemperature(hoursBack: hoursBack),
      fetchRespiratoryRate(hoursBack: hoursBack),
      fetchBloodGlucose(hoursBack: hoursBack),
      fetchWorkout(hoursBack: hoursBack),
      fetchDistanceDelta(hoursBack: hoursBack),
    ]);

    int? stepsToday;
    try {
      stepsToday = await _health.getTotalStepsInInterval(
        DateTime(now.year, now.month, now.day),
        now,
      );
    } catch (e) {
      debugPrint('[HealthFetcher] getTotalStepsInInterval failed: $e');
    }

    final result = HealthFetchResult(
      heartRate: results[0],
      restingHeartRate: results[1],
      steps: results[2],
      bloodOxygen: results[3],
      bloodPressureSystolic: results[4],
      bloodPressureDiastolic: results[5],
      weight: results[6],
      height: results[7],
      activeEnergyBurned: results[8],
      sleepAsleep: results[9],
      sleepAwake: results[10],
      sleepDeep: results[11],
      sleepRem: results[12],
      bodyTemperature: results[13],
      respiratoryRate: results[14],
      bloodGlucose: results[15],
      workout: results[16],
      distanceDelta: results[17],
      stepsToday: stepsToday,
      fetchedAt: now,
    );

    _logSummary(result);
    return result;
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  Future<List<HealthDataPoint>> _fetch(
    HealthDataType type,
    int hoursBack,
  ) async {
    if (!_health.isDataTypeAvailable(type)) return [];
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: _start(hoursBack),
        endTime: DateTime.now(),
        types: [type],
      );
      return _deduplicate(points);
    } catch (e) {
      debugPrint('[HealthFetcher] ${type.name} error: $e');
      return [];
    }
  }

  List<HealthDataPoint> _deduplicate(List<HealthDataPoint> points) {
    final seen = <String, HealthDataPoint>{};
    for (final p in points) {
      seen['${p.dateFrom}-${p.dateTo}-${p.typeString}-${p.value}'] = p;
    }
    return seen.values.toList()
      ..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
  }

  void _logSummary(HealthFetchResult result) {
    final countByType = <String, int>{};
    for (final p in result.all) {
      countByType[p.typeString] = (countByType[p.typeString] ?? 0) + 1;
    }
    final summary = countByType.entries
        .map((e) => '${e.key}:${e.value}')
        .join(', ');
    debugPrint('[DeviceHealth] ${result.totalPoints} points | $summary');
    if (result.stepsToday != null) {
      debugPrint('[DeviceHealth] Steps today: ${result.stepsToday}');
    }
  }
}
