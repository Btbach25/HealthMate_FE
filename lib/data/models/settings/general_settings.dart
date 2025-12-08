import 'package:equatable/equatable.dart';

/// Model for general app settings
class GeneralSettings extends Equatable {
  final bool darkMode;
  final String language;
  final String dateFormat;
  final String timeFormat;

  const GeneralSettings({
    this.darkMode = false,
    this.language = 'vi',
    this.dateFormat = 'dd/mm/yyyy',
    this.timeFormat = '24h',
  });

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    return GeneralSettings(
      darkMode: json['dark_mode'] as bool? ?? false,
      language: json['language'] as String? ?? 'vi',
      dateFormat: json['date_format'] as String? ?? 'dd/mm/yyyy',
      timeFormat: json['time_format'] as String? ?? '24h',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dark_mode': darkMode,
      'language': language,
      'date_format': dateFormat,
      'time_format': timeFormat,
    };
  }

  GeneralSettings copyWith({
    bool? darkMode,
    String? language,
    String? dateFormat,
    String? timeFormat,
  }) {
    return GeneralSettings(
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }

  @override
  List<Object> get props => [darkMode, language, dateFormat, timeFormat];
}

