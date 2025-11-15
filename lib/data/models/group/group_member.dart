import 'package:fe/core/utils/converter.dart';

import '../../enums/group_member_role.dart';
import '../../enums/group_member_status.dart';

class GroupMember {
  final String groupId;
  final String userId;
  final GroupMemberRole role;
  final GroupMemberStatus status;
  final String invitedBy;
  final DateTime? joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupMember({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
    required this.invitedBy,
    this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: GroupMemberRole.fromValue(json['role'] as String?),
      status: GroupMemberStatus.fromValue(json['status'] as String?),
      invitedBy: json['invited_by'] as String,
      joinedAt: cvToDate(json['joined_at'] as String?),
      createdAt: cvToDateRequired(json['created_at'] as String),
      updatedAt: cvToDateRequired(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'user_id': userId,
      'role': role.value,
      'status': status.value,
      'invited_by': invitedBy,
      'joined_at': joinedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GroupMember copyWith({
    String? groupId,
    String? userId,
    GroupMemberRole? role,
    GroupMemberStatus? status,
    String? invitedBy,
    DateTime? joinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      invitedBy: invitedBy ?? this.invitedBy,
      // Lưu ý xử lý giá trị null cho joinedAt
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}