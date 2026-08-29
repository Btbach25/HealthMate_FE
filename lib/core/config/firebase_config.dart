import 'package:fe/core/config/app_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Khởi tạo Firebase cho mọi nền tảng.
///
/// - Android/iOS: cấu hình nằm trong `google-services.json` / `GoogleService-Info.plist`
///   nên `initializeApp()` không cần tham số.
/// - Web: bắt buộc truyền [FirebaseOptions] thủ công, giá trị lấy từ `.env`.
///
/// Hàm này **không bao giờ ném lỗi**: thiếu cấu hình thì app vẫn chạy, chỉ mất
/// các tính năng phụ thuộc Firebase (push notification).
Future<bool> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return true;

  try {
    if (kIsWeb) {
      if (!AppConfig.hasFirebaseWebConfig) {
        debugPrint(
          '[Firebase] Thiếu FIREBASE_* trong .env — bỏ qua Firebase trên Web.',
        );
        return false;
      }
      await Firebase.initializeApp(options: _webOptions);
    } else {
      await Firebase.initializeApp();
    }
    return true;
  } catch (e) {
    debugPrint('[Firebase] initializeApp thất bại, chạy tiếp không Firebase: $e');
    return false;
  }
}

FirebaseOptions get _webOptions => FirebaseOptions(
  apiKey: AppConfig.firebaseApiKey,
  appId: AppConfig.firebaseAppId,
  messagingSenderId: AppConfig.firebaseMessagingSenderId,
  projectId: AppConfig.firebaseProjectId,
  authDomain: AppConfig.firebaseAuthDomain.isEmpty
      ? null
      : AppConfig.firebaseAuthDomain,
  storageBucket: AppConfig.firebaseStorageBucket.isEmpty
      ? null
      : AppConfig.firebaseStorageBucket,
);
