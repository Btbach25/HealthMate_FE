/// Một lần nhắc uống thuốc trong ngày (giờ nhắc + đã uống hay chưa).
class MedicationReminder {
  final String id;
  final String medicationId;
  final String time; // "HH:mm"
  final bool isEnabled;
  final DateTime? lastTaken;
  final int missedCount;

  const MedicationReminder({
    required this.id,
    required this.medicationId,
    required this.time,
    this.isEnabled = true,
    this.lastTaken,
    this.missedCount = 0,
  });

  bool get isTakenToday {
    if (lastTaken == null) return false;
    final now = DateTime.now();
    return lastTaken!.year == now.year &&
        lastTaken!.month == now.month &&
        lastTaken!.day == now.day;
  }

  factory MedicationReminder.fromJson(Map<String, dynamic> json) =>
      MedicationReminder(
        id: json['id'] as String,
        medicationId: json['medication_id'] as String,
        time: json['time'] as String,
        isEnabled: json['is_enabled'] as bool? ?? true,
        lastTaken: json['last_taken'] != null
            ? DateTime.parse(json['last_taken'] as String)
            : null,
        missedCount: json['missed_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'medication_id': medicationId,
        'time': time,
        'is_enabled': isEnabled,
        'last_taken': lastTaken?.toIso8601String(),
        'missed_count': missedCount,
      };

  MedicationReminder copyWith({
    String? id,
    String? medicationId,
    String? time,
    bool? isEnabled,
    DateTime? lastTaken,
    bool clearLastTaken = false,
    int? missedCount,
  }) =>
      MedicationReminder(
        id: id ?? this.id,
        medicationId: medicationId ?? this.medicationId,
        time: time ?? this.time,
        isEnabled: isEnabled ?? this.isEnabled,
        lastTaken: clearLastTaken ? null : (lastTaken ?? this.lastTaken),
        missedCount: missedCount ?? this.missedCount,
      );
}
