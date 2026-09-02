import 'dart:convert';

import 'package:fe/core/config/app_config.dart';
import 'package:fe/core/utils/auth_http_helper.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

class ReadinessService {
  final AuthHttpHelper _http;

  ReadinessService(
    LocalStorageService localStorage, {
    Future<String?> Function()? onRefresh,
  }) : _http = AuthHttpHelper(localStorage, onRefresh);

  String get _baseUrl => AppConfig.apiBaseUrl;

  /// Gọi POST /metrics/readiness, trả về readiness_score [0-100] hoặc null nếu lỗi.
  Future<double?> getScore({
    required double heartRate,
    required double sleepDuration,
    required String stressLevel,
    required double bloodOxygen,
    double? steps,
    double? caloriesBurned,
  }) async {
    final reqBody = <String, dynamic>{
      'heart_rate': heartRate,
      'sleep_duration': sleepDuration,
      'stress_level': stressLevel,
      'blood_oxygen': bloodOxygen,
      if (steps != null) 'steps': steps,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
    };

    debugPrint('[readiness] → POST $_baseUrl/metrics/readiness');
    debugPrint('[readiness] → ${reqBody.length} trường');

    try {
      final response = await _http.post(
        Uri.parse('$_baseUrl/metrics/readiness'),
        body: jsonEncode(reqBody),
      );

      debugPrint('[readiness] ← status: ${response.statusCode}');
      debugPrint('[readiness] ← ${response.body.length}B');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['readiness_score'];
        return (raw as num?)?.toDouble();
      }
    } catch (e) {
      debugPrint('[readiness] ← exception: $e');
    }
    return null;
  }
}
