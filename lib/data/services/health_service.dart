import 'dart:convert';

import 'package:fe/core/config/app_config.dart';
import 'package:fe/core/utils/auth_http_helper.dart';
import 'package:fe/data/models/health/blood_pressure.dart';
import 'package:fe/data/models/health/health_overview.dart';
import 'package:fe/data/models/health/heart_rate.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

class HealthService {
  final LocalStorageService _localStorage;
  late final AuthHttpHelper _http;

  HealthService(this._localStorage, {Future<String?> Function()? onRefresh})
      : _http = AuthHttpHelper(_localStorage, onRefresh);

  String get _baseUrl => AppConfig.apiBaseUrl;

  /// Gọi GET /health/latest. Nếu BE trả 404 hoặc lỗi (endpoint chưa có / lỗi mạng) → trả [HealthOverview.empty()] để app không crash.
  /// Đặt HEALTH_LATEST_ENABLED=false trong .env để tắt gọi API (tránh 404 khi BE chưa có endpoint).
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

    if (hrValue == null && bpValue == null) {
      throw Exception('Chưa lấy được dữ liệu sức khỏe trên tài khoản.');
    }

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
        final decoded = jsonDecode(response.body);
        List data = [];
        if (decoded is Map<String, dynamic>) {
          data = (decoded['data'] as List?) ?? [];
        } else if (decoded is List) {
          data = decoded;
        }
        if (data.isEmpty) return null;
        final last = data.last as Map<String, dynamic>;
        return (last['value'] as num?)?.toDouble();
      }
      final preview = response.body.length > 300
          ? '${response.body.substring(0, 300)}...'
          : response.body;
      debugPrint('[HealthService] $metricType: ${response.statusCode} | $preview');
    } catch (e) {
      debugPrint('[HealthService] $metricType error: $e');
    }
    return null;
  }
}
