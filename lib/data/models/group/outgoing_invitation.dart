import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/converter.dart';
import 'package:fe/data/enums/group_member_role.dart';
import 'package:fe/data/enums/group_member_status.dart';
import 'package:fe/data/enums/login_provider.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/enums/user_role.dart';
import 'package:fe/data/enums/user_status.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/models/group/family_group.dart';

class OutgoingInvitation extends Equatable {
  final String id;
  final String groupId;
  final FamilyGroup? group; // Reuse FamilyGroup model
  final User? invitee; // Reuse User model
  final String? relationship;
  final GroupMemberStatus status;
  final DateTime sentAt;
  final List<MetricType> sharedMetrics;

  const OutgoingInvitation({
    required this.id,
    required this.groupId,
    this.group,
    this.invitee,
    this.relationship,
    required this.status,
    required this.sentAt,
    required this.sharedMetrics,
  });

  // Convenience getters for backward compatibility with flat data
  String get groupName => group?.name ?? '';
  String get inviteeEmail => invitee?.email ?? '';
  String get inviteeName => invitee?.name ?? '';

  factory OutgoingInvitation.fromJson(Map<String, dynamic> json) {
    return OutgoingInvitation(
      id: cvToString(json['id']),
      groupId: cvToString(json['group_id']),
      group: _parseGroup(json),
      invitee: _parseInvitee(json),
      relationship: cvToStringOrNull(json['relationship']),
      status: GroupMemberStatus.fromValue(cvToStringOrNull(json['status'])),
      sentAt: cvToDateRequired(json['sent_at']),
      sharedMetrics: cvToList(
        json['shared_metrics'],
        (e) => MetricType.fromValue(cvToString(e)),
      ),
    );
  }

  /// Parses group from nested or flat JSON structure
  static FamilyGroup? _parseGroup(Map<String, dynamic> json) {
    return cvToNestedObject<FamilyGroup>(
      json,
      'group',
      (nested) => FamilyGroup.fromJson(nested),
      (flat) {
        final groupName = flat['group_name'];
        if (groupName == null) return null;

        final sentAt = cvToDateRequired(flat['sent_at']);
        return FamilyGroup(
          id: cvToString(flat['group_id']),
          name: cvToString(groupName),
          memberCount: cvToInt(flat['member_count'] ?? 0),
          userRole: GroupMemberRole.member,
          createdAt: sentAt,
          updatedAt: sentAt,
          sharedMetrics: cvToList(
            flat['shared_metrics'],
            (e) => MetricType.fromValue(cvToString(e)),
          ),
          ownerId: cvToString(flat['owner_id'] ?? ''),
        );
      },
    );
  }

  /// Parses invitee from nested or flat JSON structure
  static User? _parseInvitee(Map<String, dynamic> json) {
    return cvToNestedObject<User>(
      json,
      'invitee',
      (nested) => User.fromJson(nested),
      (flat) {
        final inviteeEmail = flat['invitee_email'];
        if (inviteeEmail == null) return null;

        final sentAt = cvToDateRequired(flat['sent_at']);
        return User(
          id: cvToString(flat['invitee_id'] ?? ''),
          email: cvToString(inviteeEmail),
          name: cvToString(flat['invitee_name'] ?? ''),
          role: UserRole.user,
          status: UserStatus.verified,
          provider: LoginProvider.email,
          createdAt: sentAt,
          updatedAt: sentAt,
        );
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'relationship': relationship,
      'status': status.value,
      'sent_at': sentAt.toIso8601String(),
      'shared_metrics': sharedMetrics.map((e) => e.value).toList(),
      // Include nested objects for modern API
      if (group != null) ...{
        'group': group!.toJson(),
        'group_name': group!.name, // Backward compatibility
      },
      if (invitee != null) ...{
        'invitee': invitee!.toJson(),
        'invitee_name': invitee!.name, // Backward compatibility
        'invitee_email': invitee!.email, // Backward compatibility
      },
    };
  }

  /// Converts OutgoingInvitation to JSON string
  String toJsonString() {
    return cvJsonToString(toJson());
  }

  /// Creates OutgoingInvitation from JSON string
  factory OutgoingInvitation.fromJsonString(String source) {
    final json = cvStringToJson(source);
    return OutgoingInvitation.fromJson(json);
  }

  OutgoingInvitation copyWith({
    String? id,
    String? groupId,
    FamilyGroup? group,
    User? invitee,
    String? relationship,
    GroupMemberStatus? status,
    DateTime? sentAt,
    List<MetricType>? sharedMetrics,
  }) {
    return OutgoingInvitation(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      group: group ?? this.group,
      invitee: invitee ?? this.invitee,
      relationship: relationship ?? this.relationship,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      sharedMetrics: sharedMetrics ?? this.sharedMetrics,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        group,
        invitee,
        relationship,
        status,
        sentAt,
        sharedMetrics,
      ];
}

