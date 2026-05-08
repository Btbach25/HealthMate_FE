import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/converter.dart';
import 'package:fe/data/enums/group_member_role.dart';
import 'package:fe/data/enums/metric_type.dart';

class FamilyGroup extends Equatable {
  final String id;
  final String name;
  final int memberCount;
  final GroupMemberRole userRole;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivity;
  final int pendingInvitations;
  final List<MetricType> sharedMetrics;
  final String ownerId;
  final bool medicationSharingAllowed;

  const FamilyGroup({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.userRole,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivity,
    this.pendingInvitations = 0,
    required this.sharedMetrics,
    required this.ownerId,
    this.medicationSharingAllowed = false,
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: cvToString(json['id']),
      name: cvToString(json['name']),
      memberCount: cvToInt(json['member_count']),
      userRole: GroupMemberRole.fromValue(cvToStringOrNull(json['user_role'])),
      createdAt: cvToDateRequired(json['created_at']),
      updatedAt: cvToDateRequired(json['updated_at']),
      lastActivity: cvToDateOrNull(json['last_activity']),
      pendingInvitations: cvToInt(json['pending_invitations']),
      sharedMetrics: cvToList(
        json['shared_metrics'],
        (e) => MetricType.fromValue(cvToString(e)),
      ),
      ownerId: cvToString(json['owner_id']),
      medicationSharingAllowed: json['medication_sharing_allowed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'member_count': memberCount,
      'user_role': userRole.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_activity': lastActivity?.toIso8601String(),
      'pending_invitations': pendingInvitations,
      'shared_metrics': sharedMetrics.map((e) => e.value).toList(),
      'owner_id': ownerId,
      'medication_sharing_allowed': medicationSharingAllowed,
    };
  }

  /// Converts FamilyGroup to JSON string
  String toJsonString() {
    return cvJsonToString(toJson());
  }

  /// Creates FamilyGroup from JSON string
  factory FamilyGroup.fromJsonString(String source) {
    final json = cvStringToJson(source);
    return FamilyGroup.fromJson(json);
  }

  FamilyGroup copyWith({
    String? id,
    String? name,
    int? memberCount,
    GroupMemberRole? userRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivity,
    int? pendingInvitations,
    List<MetricType>? sharedMetrics,
    String? ownerId,
    bool? medicationSharingAllowed,
  }) {
    return FamilyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      memberCount: memberCount ?? this.memberCount,
      userRole: userRole ?? this.userRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivity: lastActivity ?? this.lastActivity,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      sharedMetrics: sharedMetrics ?? this.sharedMetrics,
      ownerId: ownerId ?? this.ownerId,
      medicationSharingAllowed:
          medicationSharingAllowed ?? this.medicationSharingAllowed,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        memberCount,
        userRole,
        createdAt,
        updatedAt,
        lastActivity,
        pendingInvitations,
        sharedMetrics,
        ownerId,
        medicationSharingAllowed,
      ];
}



