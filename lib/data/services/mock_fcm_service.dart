import 'package:fe/data/services/fcm_service.dart';
import 'package:flutter/foundation.dart';

/// [FcmService] giả lập cho chế độ DEMO: **mọi method đều no-op**.
///
/// Không chạm Firebase, không xin quyền thông báo, không gửi token lên backend.
/// Nhờ vậy chạy demo trên máy chưa cấu hình `google-services.json` vẫn được.
class MockFcmService extends FcmService {
  MockFcmService(super.localStorage);

  @override
  Future<void> init() async {
    debugPrint('[MockFcm] Bỏ qua khởi tạo Firebase Messaging (chế độ DEMO)');
  }

  @override
  Future<void> registerCurrentToken() async {
    debugPrint('[MockFcm] Bỏ qua đăng ký device token (chế độ DEMO)');
  }

  @override
  Future<void> unregisterToken() async {
    debugPrint('[MockFcm] Bỏ qua xoá device token (chế độ DEMO)');
  }
}
