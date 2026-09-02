enum MedicationFrequencyType { daily, weekly, monthly, asNeeded }

extension MedicationFrequencyTypeX on MedicationFrequencyType {
  String get label {
    switch (this) {
      case MedicationFrequencyType.daily:
        return 'Hàng ngày';
      case MedicationFrequencyType.weekly:
        return 'Hàng tuần';
      case MedicationFrequencyType.monthly:
        return 'Hàng tháng';
      case MedicationFrequencyType.asNeeded:
        return 'Khi cần thiết';
    }
  }
}

/// Tần suất uống thuốc (hằng ngày / hằng tuần / hằng tháng / khi cần)
/// gửi kèm khi tạo hoặc cập nhật thuốc.
class MedicationFrequency {
  final MedicationFrequencyType type;
  final int timesPerDay;
  final List<String> specificTimes; // ["08:00", "20:00"]

  const MedicationFrequency({
    required this.type,
    required this.timesPerDay,
    required this.specificTimes,
  });

  factory MedicationFrequency.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = MedicationFrequencyType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => MedicationFrequencyType.daily,
    );
    return MedicationFrequency(
      type: type,
      timesPerDay: json['times_per_day'] as int? ?? 1,
      specificTimes: List<String>.from(
        json['specific_times'] as List? ?? ['08:00'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'times_per_day': timesPerDay,
    'specific_times': specificTimes,
  };

  MedicationFrequency copyWith({
    MedicationFrequencyType? type,
    int? timesPerDay,
    List<String>? specificTimes,
  }) => MedicationFrequency(
    type: type ?? this.type,
    timesPerDay: timesPerDay ?? this.timesPerDay,
    specificTimes: specificTimes ?? this.specificTimes,
  );
}
