import 'dart:async' show unawaited;

import 'package:fe/app.dart';
import 'package:fe/core/config/app_config.dart';
import 'package:fe/core/config/firebase_config.dart';
import 'package:fe/core/di/app_dependencies.dart';
import 'package:fe/data/services/fcm_debug_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Xử lý push notification khi app đang bị kill / chạy nền.
///
/// Bắt buộc là hàm top-level và có `@pragma('vm:entry-point')` — Flutter chạy
/// nó trong một isolate riêng nên mọi state của app chính đều không tồn tại.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[Firebase] Bỏ qua init ở background isolate: $e');
      return;
    }
  }
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Tắt toàn bộ log chẩn đoán ở bản release.
///
/// `debugPrint` **không** bị Flutter loại bỏ khi build release — nó vẫn in ra
/// Console của trình duyệt (web) và logcat (Android), nơi bất kỳ ai mở F12 cũng
/// đọc được. Gán lại thành hàm rỗng là cách chặn duy nhất áp dụng được cho cả
/// log của package bên thứ ba.
///
/// Đây là lớp phòng thủ thứ hai. Lớp thứ nhất vẫn là **không bao giờ log dữ
/// liệu nhạy cảm ngay từ đầu** — token, response body, email — vì bản debug mà
/// lập trình viên chạy hằng ngày thì không có công tắc này.
void _silenceLogsInRelease() {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
}

Future<void> main() async {
  _silenceLogsInRelease();
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN', null);
  await AppConfig.load();

  // Chế độ demo phải tuyệt đối không chạm mạng — Firebase và FCM đều bị bỏ qua.
  if (!AppConfig.isDemoMode) {
    if (await initializeFirebase()) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    }

    // Fire-and-forget: tác vụ này chạm network/permission nên không được chặn
    // `runApp`, nếu không app sẽ đứng ở splash screen native.
    unawaited(FcmDebugService.printTokenOnStartup());
  }

  final dependencies = AppDependencies.bootstrap();
  unawaited(dependencies.fcmService.init());

  runApp(HealthMateApp(dependencies: dependencies));
}
