import 'dart:convert';

import 'package:fe/core/config/app_config.dart';
import 'package:fe/core/prescription/prescription_plan_parser.dart';
import 'package:fe/data/core/api_endpoints.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class OcrApiResult {
  final String? rawText;
  final List<ParsedPrescriptionLine> items;
  final List<String> warnings;
  final Map<String, dynamic>? meta;

  const OcrApiResult({
    this.rawText,
    this.items = const [],
    this.warnings = const [],
    this.meta,
  });

  bool get hasUsableData =>
      (rawText != null && rawText!.trim().isNotEmpty) || items.isNotEmpty;
}

/// Calls backend OCR endpoint and returns normalized data.
///
/// Returns `null` when endpoint is unavailable, response schema is unknown,
/// or networking fails, so callers can safely fallback to local OCR.
class ApiOcrService {
  ApiOcrService({
    LocalStorageService? localStorage,
    http.Client? client,
  }) : _localStorage = localStorage ?? LocalStorageService(),
       _client = client ?? http.Client();

  final LocalStorageService _localStorage;
  final http.Client _client;

  Future<OcrApiResult?> tryParsePrescription(XFile file) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}${ApiEndpoints.ocrPrescriptionParse}',
      );
      final req = http.MultipartRequest('POST', uri);
      final token = await _localStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      debugPrint(
        '[OCR_API] POST $uri token=${token != null && token.isNotEmpty}',
      );
      req.files.add(await _buildMultipartFile(file));

      final streamed = await _client.send(req);
      debugPrint('[OCR_API] status=${streamed.statusCode}');
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        final errBody = await streamed.stream.bytesToString();
        if (errBody.trim().isNotEmpty) {
          debugPrint('[OCR_API] error_body=$errBody');
        }
        return null;
      }
      final body = await streamed.stream.bytesToString();
      if (body.trim().isEmpty) return null;

      final jsonBody = json.decode(body);
      if (jsonBody is! Map<String, dynamic>) return null;

      final rawText = _extractRawText(jsonBody);
      final items = _extractItems(jsonBody);
      final warnings = _extractWarnings(jsonBody);
      final meta = jsonBody['meta'] is Map<String, dynamic>
          ? (jsonBody['meta'] as Map<String, dynamic>)
          : null;
      debugPrint(
        '[OCR_API] raw_len=${rawText?.length ?? 0} items=${items.length} warnings=${warnings.length}'
        '${meta != null ? ' meta=$meta' : ''}',
      );
      return OcrApiResult(
        rawText: rawText,
        items: items,
        warnings: warnings,
        meta: meta,
      );
    } catch (e) {
      debugPrint('[OCR_API] exception=$e');
      return null;
    }
  }

  Future<http.MultipartFile> _buildMultipartFile(XFile file) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty ? file.name : 'prescription.jpg';
      return http.MultipartFile.fromBytes('file', bytes, filename: filename);
    }
    return http.MultipartFile.fromPath('file', file.path);
  }

  String? _extractRawText(Map<String, dynamic> jsonBody) {
    final candidates = <dynamic>[
      jsonBody['raw_text'],
      jsonBody['text'],
      jsonBody['ocr_text'],
      jsonBody['content'],
    ];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c;
    }
    return null;
  }

  List<ParsedPrescriptionLine> _extractItems(Map<String, dynamic> jsonBody) {
    final candidates = <dynamic>[
      jsonBody['items'],
      jsonBody['medications'],
      jsonBody['results'],
      jsonBody['data'],
    ];
    for (final c in candidates) {
      if (c is! List) continue;
      final out = <ParsedPrescriptionLine>[];
      for (final item in c) {
        if (item is! Map<String, dynamic>) continue;
        final name = (item['name'] ?? item['drug_name'] ?? '')
            .toString()
            .trim();
        if (name.isEmpty) continue;
        final dosage = (item['dosage'] ?? item['dose'] ?? 'Theo đơn')
            .toString();
        final instructions =
            (item['instructions'] ??
                    item['usage'] ??
                    item['direction'] ??
                    'Ngày uống: 1 lần')
                .toString();
        final timesPerDay =
            (item['times_per_day'] as int?) ??
            (item['timesPerDay'] as int?) ??
            1;
        final specificTimesDyn =
            item['specific_times'] ?? item['times'] ?? const [];
        final specificTimes = specificTimesDyn is List
            ? specificTimesDyn
                  .map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : const <String>[];
        // Map allergy_hints from OCR-service (generic drug-class hints, not user-specific).
        // Field is new and optional — falls back to empty list for backward compat.
        final allergyHintsDyn = item['allergy_hints'];
        final allergyHints = allergyHintsDyn is List
            ? allergyHintsDyn
                  .map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : const <String>[];
        out.add(
          ParsedPrescriptionLine(
            name: name,
            dosage: dosage,
            instructions: instructions,
            timesPerDay: timesPerDay,
            suggestedTimes: specificTimes.isEmpty
                ? _fallbackTimes(timesPerDay)
                : specificTimes,
            likelyOral: true,
            allergyHints: allergyHints,
          ),
        );
      }
      if (out.isNotEmpty) return out;
    }
    return const [];
  }

  List<String> _extractWarnings(Map<String, dynamic> jsonBody) {
    final warnings = jsonBody['warnings'];
    if (warnings is! List) return const [];
    return warnings
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _fallbackTimes(int timesPerDay) {
    switch (timesPerDay) {
      case 1:
        return const ['08:00'];
      case 2:
        return const ['08:00', '16:30'];
      case 3:
        return const ['08:00', '13:00', '19:00'];
      default:
        return const ['08:00'];
    }
  }
}
