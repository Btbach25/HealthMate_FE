/// Một bản ghi chia sẻ lịch uống thuốc cho thành viên khác trong nhóm.
/// Ánh xạ `GET /medications/:id/shares` (JSON snake_case).
///
/// `notify_offset_minutes`: số phút trước giờ uống mà người được chia sẻ
/// nhận thông báo.
class MedicationShare {
  final String id;
  final String medicationId;
  final String groupId;
  final String sharedWithUserId;
  final int notifyOffsetMinutes;

  const MedicationShare({
    required this.id,
    required this.medicationId,
    required this.groupId,
    required this.sharedWithUserId,
    required this.notifyOffsetMinutes,
  });

  factory MedicationShare.fromJson(Map<String, dynamic> json) {
    return MedicationShare(
      id: json['id'] as String? ?? '',
      medicationId: json['medication_id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      sharedWithUserId: json['shared_with_user_id'] as String? ?? '',
      notifyOffsetMinutes: (json['notify_offset_minutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'group_id': groupId,
      'shared_with_user_id': sharedWithUserId,
      'notify_offset_minutes': notifyOffsetMinutes,
    };
  }
}
