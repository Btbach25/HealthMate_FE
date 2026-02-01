import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Dev-only JSON logger for capturing Health Connect metrics.
/// Writes one JSON object per line (NDJSON) to `health_sync.json` in
/// the app's support directory on the device.
class JsonLogger {
  /// Appends a JSON entry. Adds ISO8601 `timestamp` if not provided.
  static Future<void> append(Map<String, dynamic> entry) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/health_sync.json');

    final enriched = {
      'timestamp': DateTime.now().toIso8601String(),
      ...entry,
    };

    await file.create(recursive: true);
    final line = jsonEncode(enriched);
    await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
  }

  /// Convenience for logging a snapshot of all health metrics collected.
  static Future<void> appendHealthSnapshot(Map<String, dynamic> snapshot) async {
    await append({'type': 'health_snapshot', ...snapshot});
  }
}
