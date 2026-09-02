import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Debug helper: initialize Firebase Messaging and print FCM token.
///
/// Safe to call on startup. If Firebase is not fully configured yet
/// (google-services / plist / web config), it logs a warning instead
/// of crashing the app.
class FcmDebugService {
  static Future<void> printTokenOnStartup() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] Token is empty or unavailable.');
        return;
      }

      debugPrint('[FCM] Lấy được device token (${token.length} ký tự)');
    } catch (e) {
      debugPrint('[FCM] Failed to init/get token: $e');
    }
  }
}
