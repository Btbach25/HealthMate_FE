import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Điểm truy cập duy nhất cho mọi cấu hình runtime của app.
///
/// Toàn bộ URL và khoá đều đọc từ file `.env` ở thư mục gốc (được khai báo là
/// asset trong `pubspec.yaml` nên hoạt động cả trên Web). Nhờ vậy source code
/// không chứa giá trị nhạy cảm nào — xem `.env.example` để biết danh sách biến.
///
/// Gọi [load] đúng một lần trong `main()` trước khi chạm vào bất kỳ getter nào.
class AppConfig {
  const AppConfig._();

  static const _envFileName = '.env';

  /// Cổng api-gateway mặc định khi chạy local (chỉ dùng cho fallback dev).
  static const _localApiPort = 8080;

  static bool _loaded = false;

  /// `true` khi `.env` đã nạp thành công. `false` nghĩa là app đang chạy bằng
  /// fallback local — hữu ích để cảnh báo sớm ở màn hình dev.
  static bool get isLoaded => _loaded;

  /// Nạp `.env`. Cố tình không ném lỗi: thiếu file thì app vẫn chạy được với
  /// cấu hình local mặc định thay vì chết ngay ở splash screen.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: _envFileName);
      _loaded = true;
      debugPrint('[AppConfig] Đã nạp $_envFileName — BASE_URL=$apiBaseUrl');
    } catch (_) {
      _loaded = false;
      debugPrint(
        '[AppConfig] Không tìm thấy $_envFileName. '
        'Sao chép .env.example thành .env để cấu hình. '
        'Tạm dùng mặc định: $apiBaseUrl',
      );
    }
  }

  /// Đọc một biến môi trường, trả về chuỗi rỗng nếu chưa khai báo.
  static String _read(String key) {
    if (!_loaded) return '';
    return dotenv.env[key]?.trim() ?? '';
  }

  // ---------- API ----------

  /// URL gốc của api-gateway, luôn **không** có dấu `/` ở cuối.
  ///
  /// Ưu tiên `BASE_URL` trong `.env`; nếu thiếu thì suy ra endpoint local theo
  /// nền tảng đang chạy (Android emulator phải dùng `10.0.2.2` thay `localhost`).
  static String get apiBaseUrl {
    final configured = _read('BASE_URL');
    final base = configured.isNotEmpty ? configured : _localApiBaseUrl;
    return _stripTrailingSlash(_normalizeHostForWeb(base));
  }

  static String get _localApiBaseUrl {
    if (kIsWeb) return 'http://localhost:$_localApiPort';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Emulator Android map máy host thành 10.0.2.2, `localhost` là chính máy ảo.
      return 'http://10.0.2.2:$_localApiPort';
    }
    return 'http://127.0.0.1:$_localApiPort';
  }

  /// URL WebSocket tương ứng với [apiBaseUrl] (`http` → `ws`, `https` → `wss`).
  static String get wsBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    return uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws').toString();
  }

  // ---------- Chế độ demo ----------

  /// Override lúc build/run: `flutter run --dart-define=DEMO_MODE=true`.
  /// Ưu tiên hơn `.env` để demo nhanh mà không phải sửa file.
  static const _demoModeFromDartDefine = String.fromEnvironment('DEMO_MODE');

  /// `true` → toàn app chạy bằng dữ liệu giả trong `lib/data/mock_data/`,
  /// không phát sinh request mạng nào. Xem `AppDependencies.bootstrap`.
  static bool get isDemoMode {
    if (_demoModeFromDartDefine.isNotEmpty) {
      return _demoModeFromDartDefine.toLowerCase() == 'true';
    }
    return _read('DEMO_MODE').toLowerCase() == 'true';
  }

  // ---------- Google Sign-In ----------

  /// OAuth 2.0 Web client ID. Dùng làm `clientId` trên Web và `serverClientId`
  /// trên mobile (để backend verify được `idToken`).
  static String get googleClientId => _read('GOOGLE_CLIENT_ID');

  // ---------- Firebase (chỉ Web cần; mobile đọc từ google-services.json / plist) ----------

  static String get firebaseApiKey => _read('FIREBASE_API_KEY');
  static String get firebaseAppId => _read('FIREBASE_APP_ID');
  static String get firebaseMessagingSenderId =>
      _read('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseProjectId => _read('FIREBASE_PROJECT_ID');
  static String get firebaseAuthDomain => _read('FIREBASE_AUTH_DOMAIN');
  static String get firebaseStorageBucket => _read('FIREBASE_STORAGE_BUCKET');
  static String get firebaseVapidKey => _read('FIREBASE_VAPID_KEY');

  /// Web bắt buộc phải truyền `FirebaseOptions` thủ công; thiếu bất kỳ trường
  /// nào dưới đây thì bỏ qua Firebase thay vì để `initializeApp()` ném lỗi.
  static bool get hasFirebaseWebConfig =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  // ---------- Helpers ----------

  static String _stripTrailingSlash(String url) {
    var result = url;
    while (result.length > 1 && result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Trên trình duyệt `http://localhost:<app>` và `http://127.0.0.1:<api>` là
  /// **hai origin khác nhau** → trình duyệt bắt CORS preflight. Ép host về
  /// `localhost` để khớp origin của tab đang chạy app.
  static String _normalizeHostForWeb(String base) {
    if (!kIsWeb) return base;
    try {
      final uri = Uri.parse(base);
      if (uri.host == '127.0.0.1') {
        return uri.replace(host: 'localhost').toString();
      }
    } catch (_) {
      // URL không parse được thì giữ nguyên, để lỗi nổi lên ở tầng HTTP.
    }
    return base;
  }
}
