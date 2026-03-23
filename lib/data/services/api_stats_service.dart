import 'dart:convert';
import 'dart:io';
import 'package:fe/core/utils/auth_http_helper.dart';
import 'package:fe/data/enums/metric_status.dart';
import 'package:fe/data/models/details/chart_data_point.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/details/metric_summary.dart';
import 'package:fe/data/models/details/stats_page_data.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/data/services/stats_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiStatsService implements StatsService {
  final LocalStorageService _localStorage;
  late final AuthHttpHelper _http;

  ApiStatsService(this._localStorage, {Future<String?> Function()? onRefresh})
      : _http = AuthHttpHelper(_localStorage, onRefresh);

  String get _baseUrl {
    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  static const _metricTypes = [
    'heart_rate',
    'steps_count',
    'calories_burned',
    'blood_pressure',
    'spo2',
  ];

  @override
  Future<StatsPageData> getStatsPageData({String range = '7d'}) async {
    final user = await _localStorage.getUser();
    if (user == null || user.isEmpty) return StatsPageData.empty();

    final results = await Future.wait(
      _metricTypes.map((m) => _fetchPoints(user.id, m, range)),
    );

    final metrics = <MetricSummary>[];
    for (int i = 0; i < _metricTypes.length; i++) {
      final points = results[i];
      if (points == null || points.isEmpty) continue;
      metrics.add(_buildSummary(_metricTypes[i], points));
    }

    return StatsPageData(
      totalReadings: metrics.fold(0, (sum, m) => sum + m.readingCount),
      totalTypes: metrics.length,
      metrics: metrics,
    );
  }

  @override
  Future<List<MetricChart>> getChartData({String range = '7d'}) async {
    final user = await _localStorage.getUser();
    if (user == null || user.isEmpty) return [];

    final results = await Future.wait(
      _metricTypes.map((m) => _fetchPoints(user.id, m, range)),
    );

    final charts = <MetricChart>[];
    for (int i = 0; i < _metricTypes.length; i++) {
      final points = results[i];
      if (points == null || points.isEmpty) continue;

      final dataPoints = points
          .map((p) => ChartDataPoint(
                time: DateTime.parse(p['timestamp'] as String),
                value: (p['value'] as num).toDouble(),
              ))
          .toList();

      charts.add(MetricChart(
        id: _metricTypes[i],
        title: _metricTitle(_metricTypes[i]),
        unit: _metricUnit(_metricTypes[i]),
        dataPointCount: dataPoints.length,
        lineColor: _metricColor(_metricTypes[i]),
        points: dataPoints,
      ));
    }
    return charts;
  }

  Future<List<Map<String, dynamic>>?> _fetchPoints(
      String userId, String metricType, String range) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/metrics/charts').replace(queryParameters: {
        'user_id': userId,
        'metric_type': metricType,
        'range': range,
      });
      final response = await _http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List? data;
        if (decoded is Map<String, dynamic>) {
          data = decoded['data'] as List?;
        } else if (decoded is List) {
          data = decoded;
        }
        debugPrint('[ApiStatsService] $metricType: ${data?.length ?? 0} points');
        return data?.cast<Map<String, dynamic>>();
      }
      final preview = response.body.length > 300
          ? '${response.body.substring(0, 300)}...'
          : response.body;
      debugPrint('[ApiStatsService] $metricType: ${response.statusCode} | $preview');
    } catch (e) {
      debugPrint('[ApiStatsService] $metricType error: $e');
    }
    return null;
  }

  MetricSummary _buildSummary(
      String metricType, List<Map<String, dynamic>> points) {
    final values = points.map((p) => (p['value'] as num).toDouble()).toList();
    final timestamps = points
        .map((p) => DateTime.parse(p['timestamp'] as String))
        .toList();

    final latest = values.last;
    final lastUpdate = timestamps.last;

    double? trend;
    if (values.length >= 2) {
      final first = values.first;
      if (first != 0) {
        trend = ((latest - first) / first) * 100;
      }
    }

    return MetricSummary(
      id: metricType,
      title: _metricTitle(metricType),
      unit: _metricUnit(metricType),
      iconName: _metricIcon(metricType),
      latestValue: latest,
      lastUpdate: lastUpdate,
      readingCount: values.length,
      trendPercentage: trend,
      status: _computeStatus(metricType, latest),
      isIncreaseGood: _isIncreaseGood(metricType),
    );
  }

  String _metricTitle(String m) {
    switch (m) {
      case 'heart_rate': return 'Nhịp tim';
      case 'steps_count': return 'Số bước chân';
      case 'calories_burned': return 'Calories tiêu thụ';
      case 'blood_pressure': return 'Huyết áp tâm thu';
      case 'spo2': return 'SpO2';
      default: return m;
    }
  }

  String _metricUnit(String m) {
    switch (m) {
      case 'heart_rate': return 'bpm';
      case 'steps_count': return 'bước';
      case 'calories_burned': return 'kcal';
      case 'blood_pressure': return 'mmHg';
      case 'spo2': return '%';
      default: return '';
    }
  }

  String _metricIcon(String m) {
    switch (m) {
      case 'steps_count': return 'steps';
      default: return 'heart';
    }
  }

  Color _metricColor(String m) {
    switch (m) {
      case 'heart_rate': return Colors.red.shade400;
      case 'steps_count': return Colors.green.shade600;
      case 'calories_burned': return Colors.orange.shade600;
      case 'blood_pressure': return Colors.purple.shade400;
      case 'spo2': return Colors.blue.shade400;
      default: return Colors.grey;
    }
  }

  MetricStatus _computeStatus(String m, double v) {
    switch (m) {
      case 'heart_rate':
        if (v < 60 || v > 100) return MetricStatus.warning;
        return MetricStatus.normal;
      case 'spo2':
        if (v < 90) return MetricStatus.danger;
        if (v < 95) return MetricStatus.warning;
        return MetricStatus.normal;
      case 'blood_pressure':
        if (v > 140) return MetricStatus.danger;
        if (v > 120) return MetricStatus.warning;
        return MetricStatus.normal;
      default:
        return MetricStatus.normal;
    }
  }

  bool _isIncreaseGood(String m) {
    switch (m) {
      case 'steps_count':
      case 'calories_burned':
      case 'spo2':
        return true;
      default:
        return false;
    }
  }
}
