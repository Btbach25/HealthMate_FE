import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fe/core/utils/json_logger.dart';

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

  // Rút gọn danh sách types để tăng khả năng cấp quyền/thành công trên Health Connect.
  static final List<HealthDataType> allTypes = [
    // Cơ bản, phổ biến
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    // Sleep
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    // Khoảng cách/hoạt động
    HealthDataType.ACTIVE_ENERGY_BURNED,
    // Hô hấp và máu
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_GLUCOSE,
    // Nhiệt độ
    HealthDataType.BODY_TEMPERATURE,
  ];

  Future<bool> _ensurePermissions() async {
    // Skip entirely on web to avoid unsupported platform errors
    if (kIsWeb) return false;
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile) return false;
    if (_permissionsRequested) return true;

    // Configure health package (required before requesting permissions)
    try {
      await _health.configure();
    } catch (_) {}

    if (defaultTargetPlatform == TargetPlatform.android) {
      var status = await Permission.activityRecognition.status;
      if (status.isDenied) {
        status = await Permission.activityRecognition.request();
      }
    }

    // Xin quyền cho tập rút gọn trước, tăng tỷ lệ được cấp quyền.
    bool? granted = await _health.requestAuthorization(allTypes);
    _permissionsRequested = granted == true;
    return _permissionsRequested;
  }

  /// Yêu cầu quyền Health Connect thủ công (gọi trước khi lấy dữ liệu).
  Future<bool> requestPermissionsManually() async {
    // Gọi thẳng requestAuthorization cho tất cả loại dữ liệu
    try {
      // Configure before authorization to ensure proper launcher setup
      try {
        await _health.configure();
      } catch (_) {}

      if (defaultTargetPlatform == TargetPlatform.android) {
        var status = await Permission.activityRecognition.status;
        if (status.isDenied) {
          status = await Permission.activityRecognition.request();
        }
      }
      final granted = await _health.requestAuthorization(allTypes);
      _permissionsRequested = granted == true;
      return _permissionsRequested;
    } catch (_) {
      return false;
    }
  }

  Future<DeviceHealthResult?> fetchAll({int daysBack = 3, DateTime? startTime}) async {
    final ok = await _ensurePermissions();
    if (!ok) return null;

    final now = DateTime.now();
    final start = startTime ?? now.subtract(Duration(days: daysBack));

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

  /// Fetch and also write a JSON snapshot for debugging.
  Future<DeviceHealthResult?> fetchAllAndLog({int daysBack = 3, DateTime? startTime}) async {
    final result = await fetchAll(daysBack: daysBack, startTime: startTime);
    if (result == null) return null;

    // Convert HealthDataPoint list to lightweight JSON for NDJSON logging
    final pointsJson = result.dataPoints.map((p) => {
      'type': p.typeString,
      'unit': p.unitString,
      'value': p.value,
      'dateFrom': p.dateFrom.toIso8601String(),
      'dateTo': p.dateTo.toIso8601String(),
      'sourceId': p.sourceId,
      'sourceName': p.sourceName,
    }).toList();

    final snapshot = {
      'timeRange': {
        'start': (startTime ?? DateTime.now().subtract(Duration(days: daysBack))).toIso8601String(),
        'end': DateTime.now().toIso8601String(),
      },
      'counts': {
        'dataPoints': pointsJson.length,
      },
      'summary': {
        'totalSteps': result.totalSteps,
      },
      'dataPoints': pointsJson,
    };

    await JsonLogger.appendHealthSnapshot(snapshot);
    return result;
  }
}
