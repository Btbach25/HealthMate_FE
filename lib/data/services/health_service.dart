import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/core/utils/auth_http_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/health/blood_pressure.dart';
import '../models/health/heart_rate.dart';
import '../models/health/health_overview.dart';

class HealthService {
  final LocalStorageService _localStorage;
  late final AuthHttpHelper _http;

  HealthService(this._localStorage, {Future<String?> Function()? onRefresh})
      : _http = AuthHttpHelper(_localStorage, onRefresh);

  String get _baseUrl {
    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  Future<HealthOverview> getHealthOverview() async {
    final user = await _localStorage.getUser();
    if (user == null || user.isEmpty) throw Exception('Không tìm thấy user');

    final results = await Future.wait([
      _fetchLatestValue(user.id, 'heart_rate'),
      _fetchLatestValue(user.id, 'blood_pressure'),
    ]);

    final hrValue = results[0];
    final bpValue = results[1];
    final now = DateTime.now();

    return HealthOverview(
      heartRate: hrValue != null
          ? HeartRate(time: now, userId: user.id, value: hrValue)
          : null,
      bloodPressure: bpValue != null
          ? BloodPressure(time: now, userId: user.id, systolic: bpValue.round())
          : null,
    );
  }

  Future<double?> _fetchLatestValue(String userId, String metricType) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/metrics/charts').replace(queryParameters: {
        'user_id': userId,
        'metric_type': metricType,
        'range': '24h',
      });
      final response = await _http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (body['data'] as List?) ?? [];
        if (data.isEmpty) return null;
        final last = data.last as Map<String, dynamic>;
        return (last['value'] as num?)?.toDouble();
      }
      debugPrint('[HealthService] $metricType: ${response.statusCode}');
    } catch (e) {
      debugPrint('[HealthService] $metricType error: $e');
    }
    return null;
  }
}
