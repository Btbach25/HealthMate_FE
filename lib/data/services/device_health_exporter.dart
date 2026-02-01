import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'device_health_service.dart';

/// Xuất dữ liệu ra JSON phục vụ debug.
///
/// - Trên mobile (Android/iOS): KHÔNG ghi vào thiết bị theo yêu cầu.
/// - Trên desktop (Windows/macOS/Linux): ghi trực tiếp vào thư mục dự án `assets/debug/health/`.
/// - Trên Web: không ghi file, có thể bổ sung cơ chế download sau nếu cần.
class DeviceHealthExporter {
  Future<File?> saveResultAsJson(DeviceHealthResult result, {String fileName = 'health_sync.json'}) async {
    final jsonMap = _resultToMap(result);
    final jsonStr = jsonEncode(jsonMap);

    // Mobile: bỏ qua ghi file (theo yêu cầu người dùng)
    final isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    if (isMobile) {
      // In ra log để xem nhanh
      debugPrint('[HealthExporter] Skip write on mobile. Length=${jsonStr.length}');
      return null;
    }

    // Web: hiện tại bỏ qua, có thể triển khai download blob sau
    if (kIsWeb) {
      debugPrint('[HealthExporter] Skip write on web. Length=${jsonStr.length}');
      return null;
    }

    // Desktop: ghi trực tiếp vào project folder (đường dẫn tương đối)
    final outDir = Directory('assets/debug/health');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final file = File('${outDir.path}/$fileName');
    await file.writeAsString(jsonStr, flush: true);
    debugPrint('[HealthExporter] Wrote ${file.path} (${jsonStr.length} bytes)');
    return file;
  }

  Map<String, dynamic> _resultToMap(DeviceHealthResult result) {
    return {
      'fetchedAt': result.fetchedAt.toIso8601String(),
      'totalSteps': result.totalSteps,
      'dataCount': result.dataPoints.length,
      'points': result.dataPoints.map(_pointToMap).toList(),
    };
  }

  Map<String, dynamic> _pointToMap(HealthDataPoint p) {
    return {
      'type': p.type.name,
      'unit': p.unit.name,
      'value': p.value.toString(),
      'source': p.sourceName,
      'dateFrom': p.dateFrom.toIso8601String(),
      'dateTo': p.dateTo.toIso8601String(),
    };
  }
}
