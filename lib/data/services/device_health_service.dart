import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceHealthResult {
  final List<HealthDataPoint> dataPoints;
  final int? totalSteps;
  final DateTime fetchedAt;
  DeviceHealthResult({required this.dataPoints, required this.totalSteps, required this.fetchedAt});
}

class DeviceHealthService {
  DeviceHealthService();
  final Health _health = Health();
  bool _permissionsRequested = false;

  static final List<HealthDataType> allTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.WAIST_CIRCUMFERENCE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.WATER,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.WORKOUT,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.DIETARY_ENERGY_CONSUMED,
    HealthDataType.MINDFULNESS,
  ];

  Future<bool> _ensurePermissions() async {
    // Skip entirely on web to avoid unsupported platform errors
    if (kIsWeb) return false;
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile) return false;
    if (_permissionsRequested) return true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      var status = await Permission.activityRecognition.status;
      if (status.isDenied) {
        status = await Permission.activityRecognition.request();
      }
    }

    bool? granted = await _health.requestAuthorization(allTypes);
    _permissionsRequested = granted == true;
    return _permissionsRequested;
  }

  Future<DeviceHealthResult?> fetchAll({int daysBack = 3}) async {
    final ok = await _ensurePermissions();
    if (!ok) return null;

    final now = DateTime.now();
    final start = now.subtract(Duration(days: daysBack));

    // On Android optionally ensure Health Connect available
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        // Attempt install prompt then abort this cycle
        await _health.installHealthConnect();
        return null;
      }
    }

    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: allTypes,
      );
      // Deduplicate
      final unique = <String, HealthDataPoint>{};
      for (final p in points) {
        unique['${p.dateFrom}-${p.dateTo}-${p.typeString}-${p.value}'] = p;
      }
      // Total steps today
      int? totalSteps;
      try {
        totalSteps = await _health.getTotalStepsInInterval(
          DateTime(now.year, now.month, now.day),
          now,
        );
      } catch (_) {}

      return DeviceHealthResult(
        dataPoints: unique.values.toList()..sort((a,b)=>b.dateFrom.compareTo(a.dateFrom)),
        totalSteps: totalSteps,
        fetchedAt: now,
      );
    } catch (e) {
      return null;
    }
  }
}
