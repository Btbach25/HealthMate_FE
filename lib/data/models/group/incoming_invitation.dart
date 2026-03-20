import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/converter.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/enums/group_member_role.dart';
import 'package:fe/data/enums/login_provider.dart';
import 'package:fe/data/enums/user_role.dart';
import 'package:fe/data/enums/user_status.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/models/group/family_group.dart';

class IncomingInvitation extends Equatable {
  final String id;
  final String groupId;
  final FamilyGroup? group; // Reuse FamilyGroup model
  final User? inviter; // Reuse User model
  final DateTime sentAt;
  final List<MetricType> sharedMetrics;
  final int memberCount;

  const IncomingInvitation({
    required this.id,
    required this.groupId,
    this.group,
    this.inviter,
    required this.sentAt,
    required this.sharedMetrics,
    required this.memberCount,
  });

  // Convenience getters for backward compatibility with flat data
  String get groupName => group?.name ?? '';
  String get inviterName => inviter?.name ?? '';
  String get inviterEmail => inviter?.email ?? '';

  factory IncomingInvitation.fromJson(Map<String, dynamic> json) {
    // BE ListInvitations hiện trả group_id ở nested group.id, không có group_id top-level.
    // Ưu tiên field group_id nếu có, fallback sang group.id.
    final rawGroupId = json['group_id'] ?? (json['group'] is Map ? (json['group'] as Map)['id'] : null);
    return IncomingInvitation(
      id: cvToString(json['id']),
      groupId: cvToString(rawGroupId),
      group: _parseGroup(json),
      inviter: _parseInviter(json),
      sentAt: cvToDateRequired(json['sent_at']),
      sharedMetrics: cvToList(
        json['shared_metrics'],
        (e) => MetricType.fromValue(cvToString(e)),
      ),
      memberCount: cvToInt(json['member_count']),
    );
  }

  /// Parses group from nested or flat JSON structure
  static FamilyGroup? _parseGroup(Map<String, dynamic> json) {
    return cvToNestedObject<FamilyGroup>(
      json,
      'group',
      (nested) {
        // Nested group trong ListInvitations hiện chỉ có id, name, member_count.
        // created_at/updated_at không có nên dùng sent_at của invitation làm thời gian mặc định.
        final sentAt = cvToDateRequired(json['sent_at']);
        return FamilyGroup(
          id: cvToString(nested['id']),
          name: cvToString(nested['name']),
          memberCount: cvToInt(nested['member_count']),
          userRole: GroupMemberRole.member,
          createdAt: sentAt,
          updatedAt: sentAt,
          sharedMetrics: cvToList(
            json['shared_metrics'],
            (e) => MetricType.fromValue(cvToString(e)),
          ),
          ownerId: cvToString(nested['owner_id'] ?? ''),
        );
      },
      (flat) {
        final groupName = flat['group_name'];
        if (groupName == null) return null;

        final sentAt = cvToDateRequired(flat['sent_at']);
        return FamilyGroup(
          id: cvToString(flat['group_id']),
          name: cvToString(groupName),
          memberCount: cvToInt(flat['member_count']),
          userRole: GroupMemberRole.member,
          createdAt: cvToDateRequired(flat['created_at'] ?? sentAt),
          updatedAt: cvToDateRequired(flat['updated_at'] ?? sentAt),
          sharedMetrics: cvToList(
            flat['shared_metrics'],
            (e) => MetricType.fromValue(cvToString(e)),
          ),
          ownerId: cvToString(flat['owner_id'] ?? flat['inviter_id'] ?? ''),
        );
      },
    );
  }

  /// Parses inviter from nested or flat JSON structure
  static User? _parseInviter(Map<String, dynamic> json) {
    return cvToNestedObject<User>(
      json,
      'inviter',
      (nested) => User.fromJson(nested),
      (flat) {
        final inviterEmail = flat['inviter_email'];
        if (inviterEmail == null) return null;

        final sentAt = cvToDateRequired(flat['sent_at']);
        return User(
          id: cvToString(flat['inviter_id'] ?? ''),
          email: cvToString(inviterEmail),
          name: cvToString(flat['inviter_name'] ?? ''),
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
      'sent_at': sentAt.toIso8601String(),
      'shared_metrics': sharedMetrics.map((e) => e.value).toList(),
      'member_count': memberCount,
      // Include nested objects for modern API
      if (group != null) ...{
        'group': group!.toJson(),
        'group_name': group!.name, // Backward compatibility
      },
      if (inviter != null) ...{
        'inviter': inviter!.toJson(),
        'inviter_name': inviter!.name, // Backward compatibility
        'inviter_email': inviter!.email, // Backward compatibility
      },
    };
  }

  /// Converts IncomingInvitation to JSON string
  String toJsonString() {
    return cvJsonToString(toJson());
  }

  /// Creates IncomingInvitation from JSON string
  factory IncomingInvitation.fromJsonString(String source) {
    final json = cvStringToJson(source);
    return IncomingInvitation.fromJson(json);
  }

  IncomingInvitation copyWith({
    String? id,
    String? groupId,
    FamilyGroup? group,
    User? inviter,
    DateTime? sentAt,
    List<MetricType>? sharedMetrics,
    int? memberCount,
  }) {
    return IncomingInvitation(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      group: group ?? this.group,
      inviter: inviter ?? this.inviter,
      sentAt: sentAt ?? this.sentAt,
      sharedMetrics: sharedMetrics ?? this.sharedMetrics,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        group,
        inviter,
        sentAt,
        sharedMetrics,
        memberCount,
      ];
}

