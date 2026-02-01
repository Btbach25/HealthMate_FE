import 'package:equatable/equatable.dart';

/// Model for notification settings
/// Contains all notification-related preferences
class NotificationSettings extends Equatable {
  final bool medicationReminders;
  final bool healthAlerts;
  final bool groupNotifications;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final double reminderVolume;

  const NotificationSettings({
    this.medicationReminders = true,
    this.healthAlerts = true,
    this.groupNotifications = true,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.reminderVolume = 70.0,
  });

  /// Creates NotificationSettings from JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      medicationReminders: json['medication_reminders'] as bool? ?? true,
      healthAlerts: json['health_alerts'] as bool? ?? true,
      groupNotifications: json['group_notifications'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? false,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
      reminderVolume: (json['reminder_volume'] as num?)?.toDouble() ?? 70.0,
    );
  }

  /// Converts NotificationSettings to JSON
  Map<String, dynamic> toJson() {
    return {
      'medication_reminders': medicationReminders,
      'health_alerts': healthAlerts,
      'group_notifications': groupNotifications,
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'reminder_volume': reminderVolume,
    };
  }

  /// Creates a copy with updated values
  NotificationSettings copyWith({
    bool? medicationReminders,
    bool? healthAlerts,
    bool? groupNotifications,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    double? reminderVolume,
  }) {
    return NotificationSettings(
      medicationReminders: medicationReminders ?? this.medicationReminders,
      healthAlerts: healthAlerts ?? this.healthAlerts,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      reminderVolume: reminderVolume ?? this.reminderVolume,
    );
  }

  @override
  List<Object> get props => [
        medicationReminders,
        healthAlerts,
        groupNotifications,
        pushNotifications,
        emailNotifications,
        soundEnabled,
        vibrationEnabled,
        reminderVolume,
      ];
}

