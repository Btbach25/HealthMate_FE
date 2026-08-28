import 'package:fe/data/enums/group_member_role.dart';
import 'package:fe/data/enums/group_member_status.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/mock_data/mock_family_data.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/services/family_service.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

/// [FamilyService] giả lập cho chế độ DEMO — **có state trong bộ nhớ**.
///
/// Dữ liệu khởi tạo lấy từ `MockFamilyData`, sau đó mọi thao tác đều thay đổi
/// thật trên bản sao trong RAM: tạo nhóm, mời thành viên, đồng ý/từ chối lời
/// mời, duyệt yêu cầu tham gia, đổi quyền chia sẻ, xoá thành viên, rời nhóm…
/// Nhờ vậy demo có cảm giác như app thật. State mất khi tắt app.
///
/// Quy ước id giống backend thật: `FamilyMember.id == FamilyMember.userId`
/// (xem `GroupApiMapper.toFamilyMember`), nên `removeMember` nhận id người dùng.
class MockFamilyService implements FamilyService {
  final LocalStorageService? _localStorage;

  /// Các nhóm user demo đang tham gia.
  final List<FamilyGroup> _groups;

  /// Thành viên theo từng nhóm (kể cả nhóm chưa tham gia, để xem trước).
  final Map<String, List<FamilyMember>> _membersByGroup;

  /// Lời mời đến đang chờ xử lý.
  final List<IncomingInvitation> _incoming;

  /// Lời mời đi: `pending` = chờ phản hồi, `pendingOwnerApproval` = chờ duyệt.
  final List<OutgoingInvitation> _outgoing;

  /// Quyền chia sẻ riêng cho từng cặp (nhóm → thành viên đích → danh sách chỉ số).
  final Map<String, Map<String, List<String>>> _specificMetrics = {};

  int _counter = 0;

  MockFamilyService({LocalStorageService? localStorage})
      : _localStorage = localStorage,
        _groups = List<FamilyGroup>.from(MockFamilyData.groups),
        _membersByGroup = {
          for (final entry in MockFamilyData.membersByGroup.entries)
            entry.key: List<FamilyMember>.from(entry.value),
        },
        _incoming = List<IncomingInvitation>.from(
          MockFamilyData.incomingInvitations,
        ),
        _outgoing = [
          ...MockFamilyData.outgoingInvitations,
          ...MockFamilyData.pendingApprovals,
        ];

  // ---------- Helpers ----------

  Future<void> _delay([int milliseconds = 400]) =>
      Future<void>.delayed(Duration(milliseconds: milliseconds));

  /// Id người đang đăng nhập; fallback về tài khoản demo.
  Future<String> _currentUserId() async {
    final storage = _localStorage;
    if (storage != null) {
      final user = await storage.getUser();
      if (user != null && user.isNotEmpty) return user.id;
    }
    return MockUsers.demoUserId;
  }

  Future<User> _currentUser() async {
    final storage = _localStorage;
    if (storage != null) {
      final user = await storage.getUser();
      if (user != null && user.isNotEmpty) return user;
    }
    return MockUsers.demoUser;
  }

  /// Bỏ qua tên chỉ số không hợp lệ thay vì để `MetricType.fromValue` ném lỗi.
  List<MetricType> _toMetricTypes(List<String> values) {
    final result = <MetricType>[];
    for (final value in values) {
      try {
        result.add(MetricType.fromValue(value));
      } catch (_) {
        debugPrint('[MockFamily] Bỏ qua chỉ số không hợp lệ: $value');
      }
    }
    return result;
  }

  int _indexOfGroup(String groupId) =>
      _groups.indexWhere((g) => g.id == groupId);

  List<FamilyMember> _membersOf(String groupId) =>
      _membersByGroup[groupId] ?? <FamilyMember>[];

  String _nextId(String prefix) {
    _counter++;
    return '$prefix-$_counter-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Đồng bộ lại `memberCount` / `pendingInvitations` cho khớp state hiện tại.
  FamilyGroup _synced(FamilyGroup group) {
    final members = _membersOf(group.id);
    final pending = _outgoing.where((i) => i.groupId == group.id).length;
    return group.copyWith(
      memberCount: members.isEmpty ? group.memberCount : members.length,
      pendingInvitations: pending,
    );
  }

  // ---------- Nhóm ----------

  @override
  Future<FamilyGroupSummary> getFamilyGroups() async {
    await _delay();
    final groups = _groups.map(_synced).toList();
    return FamilyGroupSummary(
      groupsJoined: groups.length,
      pendingInvitations: _incoming.length,
      groups: groups,
    );
  }

  @override
  Future<FamilyGroup> createGroup({
    required String name,
    required List<String> sharedMetrics,
    bool enableMedicationReminderShare = false,
  }) async {
    await _delay(500);

    final me = await _currentUser();
    final now = DateTime.now();
    final metrics = _toMetricTypes(sharedMetrics);
    final groupId = _nextId('demo-group-new');

    final group = FamilyGroup(
      id: groupId,
      name: name,
      memberCount: 1,
      userRole: GroupMemberRole.owner,
      createdAt: now,
      updatedAt: now,
      lastActivity: now,
      pendingInvitations: 0,
      sharedMetrics: metrics,
      ownerId: me.id,
      medicationSharingAllowed: enableMedicationReminderShare,
    );

    _groups.add(group);
    _membersByGroup[groupId] = [
      FamilyMember(
        id: me.id,
        userId: me.id,
        groupId: groupId,
        name: me.name,
        email: me.email,
        relationship: 'Tôi',
        healthStatus: HealthStatus.good,
        lastUpdated: now,
        sharedMetrics: metrics,
        medicationReminderShareAllowed: enableMedicationReminderShare,
        createdAt: now,
      ),
    ];

    debugPrint('[MockFamily] Đã tạo nhóm DEMO "$name"');
    return group;
  }

  @override
  Future<void> updateGroup({
    required String groupId,
    String? name,
    List<String>? sharedMetrics,
    bool? enableMedicationReminderShare,
  }) async {
    await _delay();
    final index = _indexOfGroup(groupId);
    if (index < 0) return;

    _groups[index] = _groups[index].copyWith(
      name: name,
      sharedMetrics:
          sharedMetrics == null ? null : _toMetricTypes(sharedMetrics),
      medicationSharingAllowed: enableMedicationReminderShare,
      updatedAt: DateTime.now(),
      lastActivity: DateTime.now(),
    );
  }

  @override
  Future<void> deleteGroup({required String groupId}) async {
    await _delay();
    _groups.removeWhere((g) => g.id == groupId);
    _membersByGroup.remove(groupId);
    _outgoing.removeWhere((i) => i.groupId == groupId);
    _specificMetrics.remove(groupId);
  }

  @override
  Future<void> leaveGroup({required String groupId}) async {
    await _delay();
    final myId = await _currentUserId();
    _membersByGroup[groupId]?.removeWhere((m) => m.userId == myId);
    _groups.removeWhere((g) => g.id == groupId);
  }

  @override
  Future<GroupDetails> getGroupDetails({
    required String groupId,
    FamilyGroup? cachedGroup,
  }) async {
    await _delay(350);

    final index = _indexOfGroup(groupId);
    final group = index >= 0
        ? _synced(_groups[index])
        : (cachedGroup ?? MockFamilyData.group3);

    return GroupDetails(
      group: group,
      members: List<FamilyMember>.from(_membersOf(groupId)),
    );
  }

  @override
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    await _delay();
    final index = _indexOfGroup(groupId);
    if (index < 0) return;

    _groups[index] = _groups[index].copyWith(
      ownerId: newOwnerId,
      userRole: GroupMemberRole.member,
      updatedAt: DateTime.now(),
    );
  }

  // ---------- Thành viên ----------

  @override
  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    await _delay();
    _membersByGroup[groupId]
        ?.removeWhere((m) => m.id == memberId || m.userId == memberId);
  }

  @override
  Future<void> updateMemberPermissions({
    required String groupId,
    required String memberId,
    required List<String> sharedMetrics,
    bool? allowMedicationReminderShare,
  }) async {
    await _delay();

    // Ghi nhớ bộ chỉ số riêng cho cặp (tôi → thành viên này).
    _specificMetrics.putIfAbsent(groupId, () => {})[memberId] =
        List<String>.from(sharedMetrics);

    final members = _membersByGroup[groupId];
    if (members == null) return;
    final index =
        members.indexWhere((m) => m.id == memberId || m.userId == memberId);
    if (index < 0) return;

    members[index] = members[index].copyWith(
      sharedMetrics: _toMetricTypes(sharedMetrics),
      medicationReminderShareAllowed: allowMedicationReminderShare,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<void> updateMySharing({
    required String groupId,
    required List<String> sharedMetrics,
  }) async {
    await _delay();
    final myId = await _currentUserId();
    final members = _membersByGroup[groupId];
    if (members == null) return;

    final index = members.indexWhere((m) => m.userId == myId);
    if (index < 0) return;

    members[index] = members[index].copyWith(
      sharedMetrics: _toMetricTypes(sharedMetrics),
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<List<String>> getMySpecificMetricsForMember({
    required String groupId,
    required String memberId,
  }) async {
    await _delay(200);
    // Rỗng = chưa đặt riêng → UI tự tick toàn bộ chỉ số chung của nhóm.
    return List<String>.from(_specificMetrics[groupId]?[memberId] ?? const []);
  }

  @override
  Future<List<FamilyMember>> getGroupMembersForInvitee({
    required String groupId,
  }) async {
    await _delay(300);
    final members = _membersOf(groupId);
    if (members.isNotEmpty) return List<FamilyMember>.from(members);
    return List<FamilyMember>.from(
      MockFamilyData.membersByGroup[groupId] ?? const <FamilyMember>[],
    );
  }

  // ---------- Lời mời ----------

  @override
  Future<void> inviteMember({
    required String groupId,
    required String email,
    String name = '',
    String? relationship,
    int? age,
    required List<String> sharedMetrics,
    String? userId,
  }) async {
    await _delay(500);

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw Exception('Vui lòng nhập email của người bạn muốn mời.');
    }

    final myId = await _currentUserId();
    if (normalizedEmail == (await _currentUser()).email.toLowerCase()) {
      throw Exception('Bạn không thể tự mời chính mình vào nhóm.');
    }

    final alreadyMember = _membersOf(groupId).any(
      (m) => (m.email ?? '').toLowerCase() == normalizedEmail,
    );
    if (alreadyMember) {
      throw Exception('Người này đã ở trong nhóm.');
    }

    final alreadyInvited = _outgoing.any(
      (i) =>
          i.groupId == groupId &&
          (i.invitee?.email ?? '').toLowerCase() == normalizedEmail,
    );
    if (alreadyInvited) {
      throw Exception('Đã gửi lời mời cho người này và đang chờ phản hồi.');
    }

    final now = DateTime.now();
    final known = MockUsers.all.where(
      (u) => u.email.toLowerCase() == normalizedEmail,
    );
    final invitee = known.isNotEmpty
        ? known.first
        : MockUsers.quocDat.copyWith(
            id: userId ?? _nextId('demo-user-invited'),
            email: normalizedEmail,
            name: name.trim().isEmpty ? normalizedEmail : name.trim(),
            createdAt: now,
            updatedAt: now,
          );

    final index = _indexOfGroup(groupId);
    _outgoing.add(
      OutgoingInvitation(
        id: _nextId('demo-inv-out'),
        groupId: groupId,
        group: index >= 0 ? _groups[index] : null,
        invitee: invitee,
        relationship: relationship,
        status: GroupMemberStatus.pending,
        sentAt: now,
        sharedMetrics: _toMetricTypes(sharedMetrics),
      ),
    );

    debugPrint('[MockFamily] $myId đã mời $normalizedEmail vào nhóm $groupId');
  }

  @override
  Future<List<IncomingInvitation>> getIncomingInvitations() async {
    await _delay(350);
    return List<IncomingInvitation>.from(_incoming);
  }

  @override
  Future<List<OutgoingInvitation>> getOutgoingInvitations() async {
    await _delay(350);
    return List<OutgoingInvitation>.from(_outgoing);
  }

  @override
  Future<void> acceptInvitation({
    required String groupId,
    required List<String> sharedMetrics,
  }) async {
    await _delay(500);

    final matches = _incoming.where((i) => i.groupId == groupId);
    if (matches.isEmpty) return;
    final invitation = matches.first;
    _incoming.removeWhere((i) => i.groupId == groupId);

    final me = await _currentUser();
    final now = DateTime.now();
    final metrics = _toMetricTypes(sharedMetrics);

    final group = (invitation.group ?? MockFamilyData.group3).copyWith(
      userRole: GroupMemberRole.member,
      updatedAt: now,
      lastActivity: now,
      pendingInvitations: 0,
    );

    if (_indexOfGroup(groupId) < 0) _groups.add(group);

    final members = _membersByGroup.putIfAbsent(
      groupId,
      () => List<FamilyMember>.from(
        MockFamilyData.membersByGroup[groupId] ?? const <FamilyMember>[],
      ),
    );
    if (!members.any((m) => m.userId == me.id)) {
      members.add(
        FamilyMember(
          id: me.id,
          userId: me.id,
          groupId: groupId,
          name: me.name,
          email: me.email,
          relationship: 'Tôi',
          healthStatus: HealthStatus.good,
          lastUpdated: now,
          sharedMetrics: metrics,
          createdAt: now,
        ),
      );
    }

    debugPrint('[MockFamily] Đã tham gia nhóm ${group.name}');
  }

  @override
  Future<void> declineInvitation({required String groupId}) async {
    await _delay(400);
    _incoming.removeWhere((i) => i.groupId == groupId);
  }

  // ---------- Duyệt yêu cầu tham gia (chỉ chủ nhóm) ----------

  @override
  Future<List<OutgoingInvitation>> getPendingApprovals({
    required String groupId,
  }) async {
    await _delay(300);
    return _outgoing
        .where((i) =>
            i.groupId == groupId &&
            i.status == GroupMemberStatus.pendingOwnerApproval)
        .toList();
  }

  @override
  Future<void> approveJoinRequest({
    required String groupId,
    required String memberId,
  }) async {
    await _delay(400);

    final matches = _outgoing.where(
      (i) => i.groupId == groupId && (i.invitee?.id ?? '') == memberId,
    );
    if (matches.isEmpty) return;
    final invitation = matches.first;
    _outgoing.remove(invitation);

    final invitee = invitation.invitee;
    if (invitee == null) return;

    final now = DateTime.now();
    final members = _membersByGroup.putIfAbsent(groupId, () => <FamilyMember>[]);
    if (members.any((m) => m.userId == invitee.id)) return;

    members.add(
      FamilyMember(
        id: invitee.id,
        userId: invitee.id,
        groupId: groupId,
        name: invitee.name,
        email: invitee.email,
        relationship: invitation.relationship,
        healthStatus: HealthStatus.healthy,
        lastUpdated: now,
        sharedMetrics: invitation.sharedMetrics,
        createdAt: now,
      ),
    );

    debugPrint('[MockFamily] Đã duyệt ${invitee.name} vào nhóm $groupId');
  }

  @override
  Future<void> rejectJoinRequest({
    required String groupId,
    required String memberId,
  }) async {
    await _delay(400);
    _outgoing.removeWhere(
      (i) => i.groupId == groupId && (i.invitee?.id ?? '') == memberId,
    );
  }
}
