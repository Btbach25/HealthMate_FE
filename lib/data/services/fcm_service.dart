import 'dart:convert';
import 'package:fe/core/config/api_base_url.dart';
import 'package:fe/core/routing/app_router.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class FcmService {
  final LocalStorageService _localStorage;

  /// Callback điều hướng khi user tap vào notification.
  /// Set từ ngoài (ví dụ: router) để navigate đúng route.
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  FcmService(this._localStorage);

  String get _baseUrl => resolveApiBaseUrl();

  /// Khởi tạo FCM: xin permission, lấy token, setup các handler.
  Future<void> init() async {
    if (kIsWeb) return;

    final messaging = FirebaseMessaging.instance;

    // Xin quyền thông báo (iOS + Android 13+)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // Lấy token và gửi lên BE
    final token = await messaging.getToken();
    debugPrint('[FCM] TOKEN: $token');
    if (token != null) await _registerToken(token);

    // Cập nhật token khi bị refresh
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed');
      _registerToken(newToken);
    });

    // Handler khi app đang foreground
    _setupForegroundHandler();

    // Handler khi user tap notification (app đang background hoặc bị terminate)
    _setupNotificationTapHandlers();
  }

  // ─── Foreground ─────────────────────────────────────────────────────────

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.messageId}');
      if (message.notification != null) {
        debugPrint('[FCM] Title: ${message.notification!.title}');
        debugPrint('[FCM] Body: ${message.notification!.body}');
      }
      if (message.data.isNotEmpty) {
        debugPrint('[FCM] Data: ${message.data}');
      }
      // Android tự hiện notification khi app foreground nếu có notification payload.
      // Nếu muốn custom UI (in-app banner), xử lý ở đây.
    });
  }

  // ─── Notification tap ────────────────────────────────────────────────────

  void _setupNotificationTapHandlers() {
    // App bị terminate → user tap notification → app mở
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[FCM] Opened from terminated state');
        _handleTap(message);
      }
    });

    // App ở background → user tap notification → app vào foreground
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Opened from background state');
      _handleTap(message);
    });
  }

  void _handleTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        context.go(route);
        return;
      }
    }
    // Fallback: gọi callback tùy chỉnh nếu có
    if (message.data.isNotEmpty) {
      onNotificationTap?.call(message.data);
    }
  }

  // ─── Register token ──────────────────────────────────────────────────────

  Future<void> _registerToken(String token) async {
    try {
      final user = await _localStorage.getUser();
      if (user == null || user.isEmpty) return;

      final accessToken = await _localStorage.getAccessToken();
      if (accessToken == null) return;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/notifications/register-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'user_id': user.id,
              'fcm_token': token,
              'platform': 'android',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[FCM] Token registered successfully');
      } else {
        debugPrint(
          '[FCM] Register token failed: ${response.statusCode} | ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[FCM] Register token error: $e');
    }
  }
}
