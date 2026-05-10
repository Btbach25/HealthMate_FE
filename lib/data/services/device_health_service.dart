import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import 'health_data_fetcher.dart';

export 'health_data_fetcher.dart' show HealthFetchResult, HealthDataFetcher;

class DeviceHealthResult {
  final List<HealthDataPoint> dataPoints;
  final int? totalSteps;
  final DateTime fetchedAt;
  DeviceHealthResult({
    required this.dataPoints,
    required this.totalSteps,
    required this.fetchedAt,
  });
}

class DeviceHealthService {
  DeviceHealthService();

  final Health _health = Health();
  late final HealthDataFetcher _fetcher = HealthDataFetcher(_health);
  bool _configured = false;

  static final List<HealthDataType> allTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.WATER,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.WORKOUT,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.DIETARY_ENERGY_CONSUMED,
  ];

  List<HealthDataType> get _supportedTypes =>
      allTypes.where(_health.isDataTypeAvailable).toList();

  Future<bool> _ensurePermissions() async {
    if (kIsWeb) return false;
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile) return false;

    if (!_configured) {
      await _health.configure();
      _configured = true;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.activityRecognition.status;
      if (status.isDenied) await Permission.activityRecognition.request();
    }

    final types = _supportedTypes;
    final alreadyGranted = await _health.hasPermissions(types);
    if (alreadyGranted == true) return true;

    final granted = await _health.requestAuthorization(types);
    if (!granted) {
      final missing = <String>[];
      for (final t in types) {
        if (await _health.hasPermissions([t]) != true) missing.add(t.name);
      }
      if (missing.isNotEmpty) {
        debugPrint('[DeviceHealth] Missing permissions: ${missing.join(', ')}');
      }
    }
    return true;
  }

  /// Lấy toàn bộ dữ liệu HC trong [hoursBack] giờ qua.
  Future<DeviceHealthResult?> fetchAll({int hoursBack = 720}) async {
    final ok = await _ensurePermissions();
    if (!ok) return null;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        await _health.installHealthConnect();
        return null;
      }
    }

    try {
      final result = await _fetcher.fetchAll(hoursBack: hoursBack);
      return DeviceHealthResult(
        dataPoints: result.all,
        totalSteps: result.stepsToday,
        fetchedAt: result.fetchedAt,
      );
    } catch (e, st) {
      debugPrint('[DeviceHealth] fetchAll error: $e\n$st');
      return null;
    }
  }

  /// Kiểm tra xem Health Connect có được kết nối và cấp quyền không.
  /// Trả về null nếu không áp dụng (non-Android), true/false nếu có/không.
  /// Không hiện dialog — chỉ check trạng thái hiện tại.
  Future<bool?> checkHCConnection() async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) { return null; }
    try {
      if (!_configured) {
        await _health.configure();
        _configured = true;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        final available = await _health.isHealthConnectAvailable();
        if (!available) return false;
      }
      final types = _supportedTypes;
      if (types.isEmpty) return false;
      final granted = await _health.hasPermissions(types);
      return granted == true;
    } catch (_) {
      return false;
    }
  }

  /// Expose fetcher để cubit/service khác gọi hàm con nếu cần.
  HealthDataFetcher get fetcher => _fetcher;
}
