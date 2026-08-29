import 'package:equatable/equatable.dart';

/// Tuỳ chọn quyền riêng tư & bảo mật (chia sẻ dữ liệu, sinh trắc học, tự
/// động khoá).
///
/// Thuần local: chỉ lưu trong SharedPreferences qua `SettingsService`,
/// không đồng bộ với backend. JSON dùng snake_case.
class PrivacySecuritySettings extends Equatable {
  final bool dataSharing;
  final bool anonymousAnalytics;
  final bool locationTracking;
  final bool biometricAuth;
  final bool autoLock;
  final String lockTimeout;

  const PrivacySecuritySettings({
    this.dataSharing = true,
    this.anonymousAnalytics = false,
    this.locationTracking = false,
    this.biometricAuth = false,
    this.autoLock = true,
    this.lockTimeout = '5 phút',
  });

  /// Creates PrivacySecuritySettings from JSON
  factory PrivacySecuritySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySecuritySettings(
      dataSharing: json['data_sharing'] as bool? ?? true,
      anonymousAnalytics: json['anonymous_analytics'] as bool? ?? false,
      locationTracking: json['location_tracking'] as bool? ?? false,
      biometricAuth: json['biometric_auth'] as bool? ?? false,
      autoLock: json['auto_lock'] as bool? ?? true,
      lockTimeout: json['lock_timeout'] as String? ?? '5 phút',
    );
  }

  /// Converts PrivacySecuritySettings to JSON
  Map<String, dynamic> toJson() {
    return {
      'data_sharing': dataSharing,
      'anonymous_analytics': anonymousAnalytics,
      'location_tracking': locationTracking,
      'biometric_auth': biometricAuth,
      'auto_lock': autoLock,
      'lock_timeout': lockTimeout,
    };
  }

  /// Creates a copy with updated values
  PrivacySecuritySettings copyWith({
    bool? dataSharing,
    bool? anonymousAnalytics,
    bool? locationTracking,
    bool? biometricAuth,
    bool? autoLock,
    String? lockTimeout,
  }) {
    return PrivacySecuritySettings(
      dataSharing: dataSharing ?? this.dataSharing,
      anonymousAnalytics: anonymousAnalytics ?? this.anonymousAnalytics,
      locationTracking: locationTracking ?? this.locationTracking,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      autoLock: autoLock ?? this.autoLock,
      lockTimeout: lockTimeout ?? this.lockTimeout,
    );
  }

  @override
  List<Object> get props => [
        dataSharing,
        anonymousAnalytics,
        locationTracking,
        biometricAuth,
        autoLock,
        lockTimeout,
      ];
}

