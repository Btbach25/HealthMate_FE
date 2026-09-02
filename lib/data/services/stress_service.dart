import 'dart:convert';

import 'package:fe/core/config/app_config.dart';
import 'package:fe/core/utils/auth_http_helper.dart';
import 'package:fe/data/models/health/stress_prediction.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

class StressService {
  final AuthHttpHelper _http;

  StressService(
    LocalStorageService localStorage, {
    Future<String?> Function()? onRefresh,
  }) : _http = AuthHttpHelper(localStorage, onRefresh);

  String get _baseUrl => AppConfig.apiBaseUrl;

  Future<StressPrediction?> predict({
    required double hrMean,
    double hrStd = 0,
    required double rmssd,
    double tempMean = 33.0,
  }) async {
    final body = <String, dynamic>{
      'hr_mean': hrMean,
      'hr_std': hrStd,
      'rmssd': rmssd,
      'temp_mean': tempMean,
    };

    debugPrint('[Stress] → POST $_baseUrl/metrics/stress/predict');
    debugPrint('[Stress] → ${body.length} trường');

    try {
      final response = await _http.post(
        Uri.parse('$_baseUrl/metrics/stress/predict'),
        body: jsonEncode(body),
      );

      debugPrint('[Stress] ← status: ${response.statusCode}');
      debugPrint('[Stress] ← ${response.body.length}B');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return StressPrediction.fromJson(data);
      }
    } catch (e) {
      debugPrint('[Stress] ← exception: $e');
    }
    return null;
  }
}
