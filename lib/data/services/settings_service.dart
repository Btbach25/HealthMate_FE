import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fe/data/models/settings/general_settings.dart';
import 'package:fe/data/models/settings/notification_settings.dart';
import 'package:fe/data/models/settings/privacy_security_settings.dart';

/// Service for managing app settings persistence
class SettingsService {
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _privacySecuritySettingsKey = 'privacy_security_settings';
  static const String _generalSettingsKey = 'general_settings';

  /// Loads notification settings from SharedPreferences
  Future<NotificationSettings> loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_notificationSettingsKey);
      
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return NotificationSettings.fromJson(json);
      }
    } catch (e) {
      // If loading fails, return default settings
      print('Error loading notification settings: $e');
    }
    
    // Return default settings if not found or error
    return const NotificationSettings();
  }

  /// Saves notification settings to SharedPreferences
  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_notificationSettingsKey, settingsJson);
    } catch (e) {
      print('Error saving notification settings: $e');
      rethrow;
    }
  }

  /// Loads privacy and security settings from SharedPreferences
  Future<PrivacySecuritySettings> loadPrivacySecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_privacySecuritySettingsKey);
      
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return PrivacySecuritySettings.fromJson(json);
      }
    } catch (e) {
      // If loading fails, return default settings
      print('Error loading privacy/security settings: $e');
    }
    
    // Return default settings if not found or error
    return const PrivacySecuritySettings();
  }

  /// Saves privacy and security settings to SharedPreferences
  Future<void> savePrivacySecuritySettings(PrivacySecuritySettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_privacySecuritySettingsKey, settingsJson);
    } catch (e) {
      print('Error saving privacy/security settings: $e');
      rethrow;
    }
  }

  /// Loads general settings from SharedPreferences
  Future<GeneralSettings> loadGeneralSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_generalSettingsKey);
      
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return GeneralSettings.fromJson(json);
      }
    } catch (e) {
      print('Error loading general settings: $e');
    }
    
    return const GeneralSettings();
  }

  /// Saves general settings to SharedPreferences
  Future<void> saveGeneralSettings(GeneralSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_generalSettingsKey, settingsJson);
    } catch (e) {
      print('Error saving general settings: $e');
      rethrow;
    }
  }
}

