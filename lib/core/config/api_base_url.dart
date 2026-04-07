import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// URL gốc api-gateway (không trailing slash).
/// Ưu tiên `BASE_URL` trong `.env.$ENV` (asset), sau đó fallback (Android emulator → 10.0.2.2).
///
/// Tránh dùng `--dart-define-from-file=.env.dev` trong launch Chrome: dễ nhúng BASE_URL cũ
/// vào build, request vẫn tới IP cũ dù đã sửa file.
String resolveApiBaseUrl() {
  final fromDotenv = dotenv.env['BASE_URL']?.trim();
  if (fromDotenv != null && fromDotenv.isNotEmpty) {
    return fromDotenv;
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://127.0.0.1:8080';
}
