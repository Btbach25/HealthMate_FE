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
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      memberCount: json['member_count'] as int? ?? 0,
      userRole: GroupMemberRole.fromValue(json['user_role'] as String?),
      createdAt: cvToDateRequired(json['created_at'] as String),
      updatedAt: cvToDateRequired(json['updated_at'] as String),
      lastActivity: cvToDate(json['last_activity'] as String?),
      pendingInvitations: json['pending_invitations'] as int? ?? 0,
      sharedMetrics: (json['shared_metrics'] as List<dynamic>?)
              ?.map((e) => MetricType.fromValue(e as String))
              .toList() ??
          [],
      ownerId: json['owner_id'] as String,
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
    };
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
      ];
}



