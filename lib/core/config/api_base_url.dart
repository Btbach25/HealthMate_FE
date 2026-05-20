import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// URL gốc api-gateway (không trailing slash).
/// Ưu tiên `BASE_URL` trong `.env` (asset), sau đó fallback (Android emulator → 10.0.2.2).
String resolveApiBaseUrl() {
  final fromDotenv = dotenv.env['BASE_URL']?.trim();
  late String base;
  if (fromDotenv != null && fromDotenv.isNotEmpty) {
    base = fromDotenv;
  } else if (kIsWeb) {
    // Web: dev server thường http://localhost:<port>
    base = 'http://localhost:8080';
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    base = 'http://10.0.2.2:8080';
  } else {
    base = 'http://127.0.0.1:8080';
  }
  return _normalizeApiBaseUrlForWeb(base);
}

/// Trên trình duyệt, `http://localhost:<app>` và `http://127.0.0.1:<api>` là **khác origin**
/// → CORS preflight; nhiều setup còn `BASE_URL=127.0.0.1` trong .env đã embed vào build cũ.
/// Ép host `127.0.0.1` → `localhost` khi chạy web để khớp origin tab app.
String _normalizeApiBaseUrlForWeb(String base) {
  if (!kIsWeb) return base;
  try {
    final u = Uri.parse(base);
    if (u.host == '127.0.0.1') {
      return u.replace(host: 'localhost').toString();
    }
  } catch (_) {}
  return base;
}
