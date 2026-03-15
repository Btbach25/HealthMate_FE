import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fe/data/services/local_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/health/health_overview.dart';

class HealthService {
  final LocalStorageService _localStorage;

  HealthService(this._localStorage);

  String get baseUrl {
    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2/api/v1';
    return 'http://localhost/api/v1';
  }

  /// Gọi GET /health/latest. Nếu BE trả 404 hoặc lỗi (endpoint chưa có / lỗi mạng) → trả [HealthOverview.empty()] để app không crash.
  /// Đặt HEALTH_LATEST_ENABLED=false trong .env để tắt gọi API (tránh 404 khi BE chưa có endpoint).
  Future<HealthOverview> getHealthOverview() async {
    try {
      final enabled = dotenv.env['HEALTH_LATEST_ENABLED'];
      if (enabled == 'false' || enabled == '0') return HealthOverview.empty();

      final token = await _localStorage.getAccessToken();
      if (token == null) return HealthOverview.empty();

      final url = Uri.parse('$baseUrl/health/latest');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return HealthOverview.fromJson(body);
        }
      }
      return HealthOverview.empty();
    } catch (_) {
      return HealthOverview.empty();
    }
  }
}