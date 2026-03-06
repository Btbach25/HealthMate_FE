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
  bool _configured = false;

  // SLEEP_IN_BED không tồn tại trên Android Health Connect (iOS only) → phải loại ra.
  // Chỉ khai báo các type đã có <uses-permission> tương ứng trong AndroidManifest.
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

  // Lọc chỉ giữ các type hợp lệ trên platform hiện tại.
  // Health Connect trên Android không có EXERCISE_TIME, DISTANCE_WALKING_RUNNING,
  // DIETARY_ENERGY_CONSUMED, v.v. — nếu pass type không hợp lệ, preparePermissionsListInternal
  // trả về null ngay → cả hasPermissions lẫn requestAuthorization đều fail.
  List<HealthDataType> get _supportedTypes =>
      allTypes.where(_health.isDataTypeAvailable).toList();

  Future<bool> _ensurePermissions() async {
    if (kIsWeb) return false;
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile) return false;

    // configure() phải được gọi trước bất kỳ API nào.
    if (!_configured) {
      await _health.configure();
      _configured = true;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.activityRecognition.status;
      if (status.isDenied) {
        await Permission.activityRecognition.request();
      }
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
      if (missing.isNotEmpty) debugPrint('[DeviceHealth] Missing permissions: ${missing.join(', ')}');
    }
    return true;
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
        types: _supportedTypes,
      );
      // Deduplicate
      final unique = <String, HealthDataPoint>{};
      for (final p in points) {
        unique['${p.dateFrom}-${p.dateTo}-${p.typeString}-${p.value}'] = p;
      }

      // Per-type summary
      final countByType = <String, int>{};
      for (final p in unique.values) {
        countByType[p.typeString] = (countByType[p.typeString] ?? 0) + 1;
      }
      debugPrint('[DeviceHealth] ${unique.length} points | ${countByType.entries.map((e) => '${e.key}:${e.value}').join(', ')}');

      // Total steps today
      int? totalSteps;
      try {
        totalSteps = await _health.getTotalStepsInInterval(
          DateTime(now.year, now.month, now.day),
          now,
        );
        debugPrint('[DeviceHealth] Steps today: $totalSteps');
      } catch (e) {
        debugPrint('[DeviceHealth] getTotalStepsInInterval failed: $e');
      }

      return DeviceHealthResult(
        dataPoints: unique.values.toList()..sort((a,b)=>b.dateFrom.compareTo(a.dateFrom)),
        totalSteps: totalSteps,
        fetchedAt: now,
      );
    } catch (e, st) {
      debugPrint('[DeviceHealth] ❌ fetchAll error: $e\n$st');
      return null;
    }
  }
}
