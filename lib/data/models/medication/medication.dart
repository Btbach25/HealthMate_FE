import 'package:fe/data/models/medication/medication_frequency.dart';
import 'package:fe/data/models/medication/medication_reminder.dart';

/// Một loại thuốc kèm tần suất và danh sách nhắc trong ngày.
/// Ánh xạ phần tử của `GET /medications` (JSON snake_case).
class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final MedicationFrequency frequency;
  final String startDate;
  final String? endDate;
  final String instructions;
  final String prescribedBy;
  final bool isActive;
  final List<MedicationReminder> reminders;

  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.instructions = '',
    this.prescribedBy = '',
    this.isActive = true,
    this.reminders = const [],
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        dosage: json['dosage'] as String,
        frequency: MedicationFrequency.fromJson(
            json['frequency'] as Map<String, dynamic>),
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String?,
        instructions: json['instructions'] as String? ?? '',
        prescribedBy: json['prescribed_by'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
        reminders: (json['reminders'] as List? ?? [])
            .map((r) =>
                MedicationReminder.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency.toJson(),
        'start_date': startDate,
        'end_date': endDate,
        'instructions': instructions,
        'prescribed_by': prescribedBy,
        'is_active': isActive,
        'reminders': reminders.map((r) => r.toJson()).toList(),
      };

  Medication copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    MedicationFrequency? frequency,
    String? startDate,
    String? endDate,
    String? instructions,
    String? prescribedBy,
    bool? isActive,
    List<MedicationReminder>? reminders,
  }) =>
      Medication(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        frequency: frequency ?? this.frequency,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        instructions: instructions ?? this.instructions,
        prescribedBy: prescribedBy ?? this.prescribedBy,
        isActive: isActive ?? this.isActive,
        reminders: reminders ?? this.reminders,
      );
}
