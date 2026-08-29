import 'dart:convert';

import 'package:fe/data/models/settings/general_settings.dart';
import 'package:fe/data/models/settings/notification_settings.dart';
import 'package:fe/data/models/settings/privacy_security_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu/đọc các nhóm cài đặt của app trong SharedPreferences (thuần local,
/// không gọi backend). Mỗi nhóm được serialize thành một chuỗi JSON dưới một
/// key riêng.
///
/// Quy ước xử lý lỗi: lỗi khi ĐỌC bị nuốt và trả về giá trị mặc định để app vẫn
/// chạy được với dữ liệu cũ/hỏng; lỗi khi GHI thì `rethrow` để UI biết mà báo
/// cho người dùng.
class SettingsService {
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _privacySecuritySettingsKey = 'privacy_security_settings';
  static const String _generalSettingsKey = 'general_settings';

  /// Đọc cài đặt thông báo; trả về mặc định nếu chưa lưu hoặc JSON hỏng.
  Future<NotificationSettings> loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_notificationSettingsKey);
      
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return NotificationSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('[Settings] Lỗi đọc notification settings: $e');
    }

    return const NotificationSettings();
  }

  /// Ghi cài đặt thông báo. Ném lại lỗi nếu ghi thất bại.
  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_notificationSettingsKey, settingsJson);
    } catch (e) {
      debugPrint('[Settings] Lỗi ghi notification settings: $e');
      rethrow;
    }
  }

  /// Đọc cài đặt quyền riêng tư & bảo mật; trả về mặc định nếu chưa lưu.
  Future<PrivacySecuritySettings> loadPrivacySecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_privacySecuritySettingsKey);
      
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return PrivacySecuritySettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('[Settings] Lỗi đọc privacy/security settings: $e');
    }

    return const PrivacySecuritySettings();
  }

  /// Ghi cài đặt quyền riêng tư & bảo mật. Ném lại lỗi nếu ghi thất bại.
  Future<void> savePrivacySecuritySettings(PrivacySecuritySettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_privacySecuritySettingsKey, settingsJson);
    } catch (e) {
      debugPrint('[Settings] Lỗi ghi privacy/security settings: $e');
      rethrow;
    }
  }

  /// Đọc cài đặt chung; trả về mặc định nếu chưa lưu.
  Future<GeneralSettings> loadGeneralSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_generalSettingsKey);
      
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return GeneralSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('[Settings] Lỗi đọc general settings: $e');
    }
    
    return const GeneralSettings();
  }

  /// Ghi cài đặt chung. Ném lại lỗi nếu ghi thất bại.
  Future<void> saveGeneralSettings(GeneralSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_generalSettingsKey, settingsJson);
    } catch (e) {
      debugPrint('[Settings] Lỗi ghi general settings: $e');
      rethrow;
    }
  }
}

