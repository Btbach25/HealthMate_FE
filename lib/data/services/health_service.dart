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

    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api/v1';
    return 'http://localhost:8080/api/v1';
  }

  Future<HealthOverview> getHealthOverview() async {
    try {
      final token = await _localStorage.getAccessToken();
      if (token == null) throw Exception('Chưa đăng nhập');

      final url = Uri.parse('$baseUrl/health/latest'); // chưa có api nên làm tạm 
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return HealthOverview.fromJson(body);
      } else {
        throw Exception('Lỗi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}