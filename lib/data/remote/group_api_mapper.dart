import 'package:fe/data/enums/group_member_role.dart';
import 'package:fe/data/enums/group_member_status.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/enums/login_provider.dart';
import 'package:fe/data/enums/user_role.dart';
import 'package:fe/data/enums/user_status.dart';

/// Map response JSON từ backend Groups API sang domain model.
class GroupApiMapper {
  GroupApiMapper._();

  static String _str(dynamic v) => v?.toString() ?? '';

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseDateOrNull(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static List<MetricType> _parseMetricTypes(dynamic v) {
    if (v is! List) return const [];
    final out = <MetricType>[];
    for (final e in v) {
      final s = _str(e);
      if (s.isEmpty) continue;
      try {
        out.add(MetricType.fromValue(s));
      } catch (_) {
        // Bỏ qua giá trị BE trả mà FE chưa map
      }
    }
    return out;
  }

  /// Backend Group JSON -> FamilyGroup (đọc từ API, fallback khi thiếu field).
  static FamilyGroup toFamilyGroup(Map<String, dynamic> json) {
    final id = _str(json['id']);
    final createdAt = _parseDate(json['created_at']);
    final updatedAt = _parseDate(json['updated_at']);
    return FamilyGroup(
      id: id,
      name: _str(json['name']),
      memberCount: _int(json['member_count']),
      userRole: GroupMemberRole.fromValue(_str(json['user_role']).isEmpty ? null : _str(json['user_role'])),
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastActivity: _parseDateOrNull(json['last_activity']),
      pendingInvitations: _int(json['pending_invitations']),
      sharedMetrics: _parseMetricTypes(json['shared_metrics']),
      ownerId: _str(json['owner_id']),
    );
  }

  /// Backend GroupMember JSON -> FamilyMember (dùng name/email từ API nếu có).
  static FamilyMember toFamilyMember(
    Map<String, dynamic> json,
    String groupId,
  ) {
    final userId = _str(json['user_id']);
    final name = _str(json['name']);
    final createdAt = _parseDate(json['created_at']);
    return FamilyMember(
      id: userId,
      userId: userId,
      groupId: _str(json['group_id']).isEmpty ? groupId : _str(json['group_id']),
      name: name.isEmpty ? 'Thành viên' : name,
      email: _str(json['email']).isEmpty ? null : _str(json['email']),
      age: null,
      relationship: null,
      avatar: null,
      healthStatus: HealthStatus.healthy,
      lastUpdated: _parseDateOrNull(json['joined_at']),
      healthConditions: const [],
      sharedMetrics: _parseMetricTypes(json['shared_metrics']),
      createdAt: createdAt,
    );
  }

  /// Danh sách Group JSON -> FamilyGroupSummary (groupsJoined từ list.length; pendingInvitations BE chưa trả thì 0).
  static FamilyGroupSummary toFamilyGroupSummary(List<dynamic> list) {
    final groups = list
        .whereType<Map<String, dynamic>>()
        .map(toFamilyGroup)
        .toList();
    return FamilyGroupSummary(
      groupsJoined: groups.length,
      pendingInvitations: 0,
      groups: groups,
    );
  }

  /// BE SentInvitationResponse (GET /groups/:id/invitations): user_id, user_email, user_name, created_at, status.
  static OutgoingInvitation sentInvitationToOutgoing({
    required Map<String, dynamic> json,
    required FamilyGroup group,
  }) {
    final sentAt = _parseDate(json['created_at']);
    final inviteeId = _str(json['user_id']);
    final inviteeEmail = _str(json['user_email'] ?? json['email']);
    final inviteeName = _str(json['user_name'] ?? json['name']);
    final invitee = (inviteeId.isNotEmpty || inviteeEmail.isNotEmpty || inviteeName.isNotEmpty)
        ? User(
            id: inviteeId,
            email: inviteeEmail,
            name: inviteeName,
            role: UserRole.user,
            status: UserStatus.verified,
            provider: LoginProvider.email,
            createdAt: sentAt,
            updatedAt: sentAt,
          )
        : null;
    return OutgoingInvitation(
      id: inviteeId,
      groupId: group.id,
      group: group,
      invitee: invitee,
      relationship: null,
      status: GroupMemberStatus.fromValue(_str(json['status']).isEmpty ? null : _str(json['status'])),
      sentAt: sentAt,
      sharedMetrics: const [],
    );
  }

  /// Một member JSON (status pending) + group -> OutgoingInvitation
  static OutgoingInvitation toOutgoingInvitation({
    required Map<String, dynamic> memberJson,
    required String groupId,
    required FamilyGroup group,
  }) {
    final sentAt = _parseDate(memberJson['created_at']);
    final inviteeId = _str(memberJson['user_id']);
    final inviteeEmail = _str(memberJson['email']);
    final inviteeName = _str(memberJson['name']);
    final invitee = (inviteeId.isNotEmpty || inviteeEmail.isNotEmpty || inviteeName.isNotEmpty)
        ? User(
            id: inviteeId,
            email: inviteeEmail,
            name: inviteeName,
            role: UserRole.user,
            status: UserStatus.verified,
            provider: LoginProvider.email,
            createdAt: sentAt,
            updatedAt: sentAt,
          )
        : null;
    return OutgoingInvitation(
      id: inviteeId,
      groupId: groupId,
      group: group,
      invitee: invitee,
      relationship: null,
      status: GroupMemberStatus.fromValue(_str(memberJson['status']).isEmpty ? null : _str(memberJson['status'])),
      sentAt: sentAt,
      sharedMetrics: _parseMetricTypes(memberJson['shared_metrics']),
    );
  }
}
