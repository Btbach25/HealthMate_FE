import 'package:fe/data/enums/group_member_role.dart';
import 'package:fe/data/enums/group_member_status.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/data/services/family_service.dart';

// Helper class to store accepted group info
class _AcceptedGroupInfo {
  final IncomingInvitation invitation;
  final List<MetricType> userSelectedMetrics;
  
  _AcceptedGroupInfo({
    required this.invitation,
    required this.userSelectedMetrics,
  });
}

class MockFamilyService implements FamilyService {
  // Track accepted invitations
  final Set<String> _acceptedInvitationIds = {};
  // Track declined invitations
  final Set<String> _declinedInvitationIds = {};
  // Track accepted invitations with user-selected metrics
  final Map<String, _AcceptedGroupInfo> _acceptedGroups = {};
  // Track outgoing invitations created by current user
  final List<OutgoingInvitation> _outgoingInvitations = [];
  // Track email addresses that have accepted/declined invitations (for simulating status updates)
  // In real app, this would be handled by backend when invitee accepts/declines
  final Map<String, GroupMemberStatus> _inviteeStatuses = {};
  // Track removed members: Map<groupId, Set<memberId>>
  final Map<String, Set<String>> _removedMembers = {};

  @override
  Future<FamilyGroupSummary> getFamilyGroups() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final twoHoursAgo = now.subtract(const Duration(hours: 2));
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final threeHoursAgo = now.subtract(const Duration(hours: 3));
    
    // Count pending outgoing invitations per group (for groups where user is admin)
    // Count from both static and dynamic invitations
    final pendingCountByGroup = <String, int>{};
    
    // Count from dynamic invitations
    for (final inv in _outgoingInvitations) {
      if (inv.status == GroupMemberStatus.pending) {
        pendingCountByGroup[inv.groupId] = (pendingCountByGroup[inv.groupId] ?? 0) + 1;
      }
    }
    
    // Also count from static mock data (for initial state)
    // Group '1' has 1 pending, Group '3' has 0 pending (declined doesn't count)
    pendingCountByGroup['1'] = (pendingCountByGroup['1'] ?? 0) + 1; // Static pending invitation

    final groups = [
      FamilyGroup(
        id: '1',
        name: 'Gia đình chính',
        memberCount: 3,
        userRole: GroupMemberRole.admin,
        createdAt: DateTime(2024, 12, 1),
        updatedAt: now,
        lastActivity: twoHoursAgo,
        pendingInvitations: pendingCountByGroup['1'] ?? 1, // Count pending outgoing invitations
        sharedMetrics: [
          MetricType.heartRate,
          MetricType.stepsCount,
          MetricType.caloriesBurnt,
        ],
        ownerId: 'current-user-id',
      ),
      FamilyGroup(
        id: '2',
        name: 'Ông bà nội',
        memberCount: 2,
        userRole: GroupMemberRole.member,
        createdAt: DateTime(2024, 12, 10),
        updatedAt: now,
        lastActivity: oneDayAgo,
        pendingInvitations: 0,
        sharedMetrics: [
          MetricType.heartRate,
          MetricType.bloodPressure,
        ],
        ownerId: 'other-user-id',
      ),
      FamilyGroup(
        id: '3',
        name: 'Anh chị em',
        memberCount: 2,
        userRole: GroupMemberRole.member,
        createdAt: DateTime(2024, 11, 15),
        updatedAt: now,
        lastActivity: threeHoursAgo,
        pendingInvitations: 2,
        sharedMetrics: [
          MetricType.stepsCount,
          MetricType.caloriesBurnt,
          MetricType.heartRate,
        ],
        ownerId: 'another-user-id',
      ),
    ];

    // Add accepted groups to the list
    final acceptedGroups = _acceptedGroups.values.map((acceptedInfo) {
      final invitation = acceptedInfo.invitation;
      return FamilyGroup(
        id: invitation.groupId,
        name: invitation.groupName,
        memberCount: invitation.memberCount + 1, // +1 for current user
        userRole: GroupMemberRole.member,
        createdAt: invitation.sentAt,
        updatedAt: now,
        lastActivity: now,
        pendingInvitations: 0,
        sharedMetrics: acceptedInfo.userSelectedMetrics, // Use user-selected metrics
        ownerId: 'other-owner-id', // The inviter is the owner
      );
    }).toList();

    final allGroups = [...groups, ...acceptedGroups];

    return FamilyGroupSummary(
      groupsJoined: allGroups.length,
      pendingInvitations: 3 - _acceptedInvitationIds.length, // Update pending count
      groups: allGroups,
    );
  }

  @override
  Future<FamilyGroup> createGroup({
    required String name,
    required List<String> sharedMetrics,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    return FamilyGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      memberCount: 1,
      userRole: GroupMemberRole.admin,
      createdAt: now,
      updatedAt: now,
      lastActivity: now,
      pendingInvitations: 0,
      sharedMetrics: sharedMetrics.map((e) => MetricType.fromValue(e)).toList(),
      ownerId: 'current-user-id',
    );
  }

  @override
  Future<void> updateGroup({
    required String groupId,
    String? name,
    List<String>? sharedMetrics,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> deleteGroup({required String groupId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Remove all outgoing invitations for this group
    _outgoingInvitations.removeWhere((inv) => inv.groupId == groupId);
  }

  @override
  Future<void> leaveGroup({required String groupId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> inviteMember({
    required String groupId,
    required String email,
    required String name,
    String? relationship,
    int? age,
    required List<String> sharedMetrics,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get group name from groups list
    final summary = await getFamilyGroups();
    final group = summary.groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Không tìm thấy nhóm'),
    );
    
    // Validate email format (additional check)
    final emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    final regex = RegExp(emailPattern);
    if (!regex.hasMatch(email.trim())) {
      throw Exception('Email không hợp lệ');
    }
    
    // Check if email already invited (simulate duplicate check)
    final hasExistingInvitation = _outgoingInvitations.any(
      (inv) => inv.inviteeEmail.toLowerCase() == email.toLowerCase() && 
               inv.groupId == groupId &&
               inv.status == GroupMemberStatus.pending,
    );
    if (hasExistingInvitation) {
      throw Exception('Email này đã được mời vào nhóm');
    }
    
    // Convert sharedMetrics strings to MetricType
    final metrics = sharedMetrics
        .map((m) => MetricType.fromValue(m))
        .toList();
    
    // Check if this email already has a status (for simulating already accepted/declined)
    // In real app, new invitations always start as pending
    final status = _inviteeStatuses[email] ?? GroupMemberStatus.pending;
    
    // Create new outgoing invitation
    final newInvitation = OutgoingInvitation(
      id: 'out-${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      groupName: group.name,
      inviteeEmail: email,
      inviteeName: name,
      relationship: relationship,
      status: status,
      sentAt: DateTime.now(),
      sharedMetrics: metrics,
    );
    
    // Add to outgoing invitations list
    _outgoingInvitations.add(newInvitation);
  }

  @override
  Future<GroupDetails> getGroupDetails({required String groupId}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    late FamilyGroup group;
    late List<FamilyMember> members;

    switch (groupId) {
      case '1':
        group = FamilyGroup(
          id: '1',
          name: 'Gia đình chính',
          memberCount: 3,
          userRole: GroupMemberRole.admin,
          createdAt: DateTime(2024, 12, 1),
          updatedAt: now,
          lastActivity: now.subtract(const Duration(hours: 2)),
          pendingInvitations: 1,
          sharedMetrics: [
            MetricType.heartRate,
            MetricType.stepsCount,
            MetricType.caloriesBurnt,
            MetricType.weight,
          ],
          ownerId: 'current-user-id',
        );
        members = [
          FamilyMember(
            id: '1',
            userId: 'user-1',
            groupId: groupId,
            name: 'Nguyễn Văn Nam',
            email: 'nam@example.com',
            age: 52,
            relationship: 'Bố',
            healthStatus: HealthStatus.needsAttention,
            lastUpdated: DateTime(2024, 11, 10),
            healthConditions: ['Huyết áp cao', 'Tiểu đường'],
            sharedMetrics: [
              MetricType.heartRate,
              MetricType.stepsCount,
              MetricType.caloriesBurnt,
              MetricType.weight,
            ],
            createdAt: DateTime(2024, 12, 1),
          ),
          FamilyMember(
            id: '2',
            userId: 'user-2',
            groupId: groupId,
            name: 'Trần Thị Mai',
            email: 'mai@example.com',
            age: 48,
            relationship: 'Mẹ',
            healthStatus: HealthStatus.good,
            lastUpdated: DateTime(2024, 11, 15),
            healthConditions: ['Khỏe mạnh'],
            sharedMetrics: [
              MetricType.heartRate,
              MetricType.stepsCount,
              MetricType.caloriesBurnt,
            ],
            createdAt: DateTime(2024, 12, 1),
          ),
          FamilyMember(
            id: '3',
            userId: 'user-3',
            groupId: groupId,
            name: 'Nguyễn Thị Lan',
            email: 'lan@example.com',
            age: 25,
            relationship: 'Con gái',
            healthStatus: HealthStatus.healthy,
            lastUpdated: DateTime(2024, 11, 13),
            healthConditions: ['Khỏe mạnh'],
            sharedMetrics: [
              MetricType.heartRate,
              MetricType.stepsCount,
            ],
            createdAt: DateTime(2024, 12, 1),
          ),
        ];
        break;
      case '2':
        group = FamilyGroup(
          id: '2',
          name: 'Ông bà nội',
          memberCount: 2,
          userRole: GroupMemberRole.member,
          createdAt: DateTime(2024, 12, 10),
          updatedAt: now,
          lastActivity: now.subtract(const Duration(days: 1)),
          pendingInvitations: 0,
          sharedMetrics: [
            MetricType.heartRate,
            MetricType.bloodPressure,
          ],
          ownerId: 'grandparent-owner-id',
        );
        members = [
          FamilyMember(
            id: '4',
            userId: 'grandpa-id',
            groupId: groupId,
            name: 'Ông Nguyễn Văn B',
            email: 'ongb@example.com',
            age: 68,
            relationship: 'Ông nội',
            healthStatus: HealthStatus.needsAttention,
            lastUpdated: DateTime(2024, 11, 22),
            healthConditions: ['Huyết áp cao'],
            sharedMetrics: [
              MetricType.heartRate,
              MetricType.bloodPressure,
            ],
            createdAt: DateTime(2024, 12, 10),
          ),
          FamilyMember(
            id: '5',
            userId: 'grandma-id',
            groupId: groupId,
            name: 'Bà Trần Thị C',
            email: 'bac@example.com',
            age: 66,
            relationship: 'Bà nội',
            healthStatus: HealthStatus.good,
            lastUpdated: DateTime(2024, 11, 23),
            healthConditions: ['Khỏe mạnh'],
            sharedMetrics: [
              MetricType.heartRate,
              MetricType.bloodPressure,
            ],
            createdAt: DateTime(2024, 12, 10),
          ),
          FamilyMember(
            id: 'current-member-2',
            userId: 'current-user-id',
            groupId: groupId,
            name: 'Bạn',
            email: 'you@example.com',
            relationship: 'Cháu',
            healthStatus: HealthStatus.healthy,
            lastUpdated: now.subtract(const Duration(days: 2)),
            healthConditions: const [],
            sharedMetrics: [
              MetricType.heartRate,
              MetricType.stepsCount,
            ],
            createdAt: DateTime(2024, 12, 10),
          ),
        ];
        break;
      case '3':
        group = FamilyGroup(
          id: '3',
          name: 'Anh chị em',
          memberCount: 2,
          userRole: GroupMemberRole.member,
          createdAt: DateTime(2024, 11, 15),
          updatedAt: now,
          lastActivity: now.subtract(const Duration(hours: 3)),
          pendingInvitations: 2,
          sharedMetrics: [
            MetricType.stepsCount,
            MetricType.caloriesBurnt,
            MetricType.heartRate,
          ],
          ownerId: 'another-user-id',
        );
        members = [
          FamilyMember(
            id: '6',
            userId: 'current-user-id',
            groupId: groupId,
            name: 'Nguyễn Văn A',
            email: 'a@example.com',
            age: 30,
            relationship: 'Anh',
            healthStatus: HealthStatus.healthy,
            lastUpdated: DateTime(2024, 11, 20),
            healthConditions: ['Khỏe mạnh'],
            sharedMetrics: [
              MetricType.stepsCount,
              MetricType.caloriesBurnt,
              MetricType.heartRate,
            ],
            createdAt: DateTime(2024, 11, 15),
          ),
          FamilyMember(
            id: '7',
            userId: 'sibling-id',
            groupId: groupId,
            name: 'Nguyễn Thị B',
            email: 'b@example.com',
            age: 28,
            relationship: 'Chị',
            healthStatus: HealthStatus.good,
            lastUpdated: DateTime(2024, 11, 18),
            healthConditions: ['Khỏe mạnh'],
            sharedMetrics: [
              MetricType.stepsCount,
              MetricType.caloriesBurnt,
            ],
            createdAt: DateTime(2024, 11, 15),
          ),
        ];
        break;
      default:
        group = FamilyGroup(
          id: groupId,
          name: 'Nhóm gia đình',
          memberCount: 1,
          userRole: GroupMemberRole.admin,
          createdAt: now,
          updatedAt: now,
          lastActivity: now,
          pendingInvitations: 0,
          sharedMetrics: [
            MetricType.heartRate,
            MetricType.stepsCount,
          ],
          ownerId: 'current-user-id',
        );
        members = [
          FamilyMember(
            id: 'current-member-$groupId',
            userId: 'current-user-id',
            groupId: groupId,
            name: 'Bạn',
            relationship: 'Chủ nhóm',
            healthStatus: HealthStatus.healthy,
            lastUpdated: now,
            healthConditions: const [],
            sharedMetrics: [
              MetricType.heartRate,
              MetricType.stepsCount,
            ],
            createdAt: now,
          ),
        ];
        break;
    }

    // Filter out removed members
    final removedMemberIds = _removedMembers[groupId] ?? <String>{};
    final filteredMembers = members.where((member) => !removedMemberIds.contains(member.id)).toList();
    
    // Update memberCount in group
    final updatedGroup = group.copyWith(memberCount: filteredMembers.length);

    return GroupDetails(group: updatedGroup, members: filteredMembers);
  }

  @override
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In real app, this would remove the member from the group
    // For mock, we just simulate the removal
  }

  @override
  Future<void> acceptInvitation({
    required String invitationId,
    required List<String> sharedMetrics,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mark invitation as accepted
    _acceptedInvitationIds.add(invitationId);
    
    // Find and store the invitation details with user-selected metrics
    final allInvitations = await _getAllIncomingInvitations();
    final invitation = allInvitations.firstWhere(
      (inv) => inv.id == invitationId,
      orElse: () => throw Exception('Invitation not found'),
    );
    
    // Convert sharedMetrics strings to MetricType
    final userSelectedMetrics = sharedMetrics
        .map((m) => MetricType.fromValue(m))
        .toList();
    
    _acceptedGroups[invitation.groupId] = _AcceptedGroupInfo(
      invitation: invitation,
      userSelectedMetrics: userSelectedMetrics,
    );
  }
  
  // Helper method to get all invitations (before filtering)
  Future<List<IncomingInvitation>> _getAllIncomingInvitations() async {
    final now = DateTime.now();
    return [
      IncomingInvitation(
        id: 'inv-1',
        groupId: 'group-inv-1',
        groupName: 'Gia đình bạn Lan',
        inviterName: 'Nguyễn Thị Lan',
        inviterEmail: 'lan@example.com',
        sentAt: now.subtract(const Duration(days: 2)),
        sharedMetrics: [
          MetricType.heartRate,
          MetricType.stepsCount,
          MetricType.weight,
        ],
        memberCount: 4,
      ),
      IncomingInvitation(
        id: 'inv-2',
        groupId: 'group-inv-2',
        groupName: 'Nhóm bạn bè',
        inviterName: 'Trần Văn Minh',
        inviterEmail: 'minh@example.com',
        sentAt: now.subtract(const Duration(hours: 5)),
        sharedMetrics: [
          MetricType.heartRate,
          MetricType.caloriesBurnt,
        ],
        memberCount: 6,
      ),
    ];
  }

  @override
  Future<void> declineInvitation({required String invitationId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Track declined invitation to filter it out from the list
    _declinedInvitationIds.add(invitationId);
    
    // Find the invitation to get inviter's email for updating outgoing invitation status
    final allIncoming = await _getAllIncomingInvitations();
    final incomingInv = allIncoming.firstWhere(
      (inv) => inv.id == invitationId,
      orElse: () => throw Exception('Không tìm thấy lời mời'),
    );
    
    // Update outgoing invitation status (simulate backend update)
    _updateOutgoingInvitationStatus(incomingInv.inviterEmail, GroupMemberStatus.declined);
  }
  
  // Helper method to simulate updating outgoing invitation status when invitee accepts/declines
  // In real app, this would be handled by the backend when the invitee accepts/declines
  void _updateOutgoingInvitationStatus(String inviteeEmail, GroupMemberStatus newStatus) {
    // Store the status for this email
    _inviteeStatuses[inviteeEmail] = newStatus;
    
    // Update all pending outgoing invitations with this email
    for (int i = 0; i < _outgoingInvitations.length; i++) {
      final inv = _outgoingInvitations[i];
      if (inv.inviteeEmail == inviteeEmail && inv.status == GroupMemberStatus.pending) {
        _outgoingInvitations[i] = OutgoingInvitation(
          id: inv.id,
          groupId: inv.groupId,
          groupName: inv.groupName,
          inviteeEmail: inv.inviteeEmail,
          inviteeName: inv.inviteeName,
          relationship: inv.relationship,
          status: newStatus,
          sentAt: inv.sentAt,
          sharedMetrics: inv.sharedMetrics,
        );
      }
    }
  }
  
  // Public method to simulate invitee accepting invitation (for testing/demo purposes)
  // In real app, this would be called by backend when invitee accepts
  void simulateInviteeAccepts(String inviteeEmail) {
    _updateOutgoingInvitationStatus(inviteeEmail, GroupMemberStatus.accepted);
  }
  
  // Public method to simulate invitee declining invitation (for testing/demo purposes)
  // In real app, this would be called by backend when invitee declines
  void simulateInviteeDeclines(String inviteeEmail) {
    _updateOutgoingInvitationStatus(inviteeEmail, GroupMemberStatus.declined);
  }

  @override
  Future<List<IncomingInvitation>> getIncomingInvitations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final allInvitations = await _getAllIncomingInvitations();
    
    // Filter out accepted and declined invitations
    return allInvitations
        .where((inv) => 
            !_acceptedInvitationIds.contains(inv.id) &&
            !_declinedInvitationIds.contains(inv.id))
        .toList();
  }

  @override
  Future<List<OutgoingInvitation>> getOutgoingInvitations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now();
    
    // Static mock data (for initial state)
    final staticInvitations = [
      OutgoingInvitation(
        id: 'out-1',
        groupId: '1',
        groupName: 'Gia đình chính',
        inviteeEmail: 'newmember@example.com',
        inviteeName: 'Nguyễn Văn Mới',
        relationship: 'Anh',
        status: GroupMemberStatus.pending,
        sentAt: now.subtract(const Duration(hours: 1)),
        sharedMetrics: [
          MetricType.heartRate,
          MetricType.stepsCount,
        ],
      ),
      OutgoingInvitation(
        id: 'out-2',
        groupId: '1',
        groupName: 'Gia đình chính',
        inviteeEmail: 'accepted@example.com',
        inviteeName: 'Trần Thị Đã Chấp Nhận',
        relationship: 'Chị',
        status: GroupMemberStatus.accepted,
        sentAt: now.subtract(const Duration(days: 1)),
        sharedMetrics: [
          MetricType.heartRate,
          MetricType.stepsCount,
          MetricType.caloriesBurnt,
        ],
      ),
      OutgoingInvitation(
        id: 'out-3',
        groupId: '3',
        groupName: 'Anh chị em',
        inviteeEmail: 'declined@example.com',
        inviteeName: 'Lê Văn Từ Chối',
        relationship: 'Em trai',
        status: GroupMemberStatus.declined,
        sentAt: now.subtract(const Duration(days: 3)),
        sharedMetrics: [
          MetricType.stepsCount,
        ],
      ),
    ];
    
    // Combine static and dynamic invitations
    // Remove duplicates by id (in case static data overlaps with dynamic)
    final allInvitations = <String, OutgoingInvitation>{};
    
    // Add static invitations first
    for (final inv in staticInvitations) {
      allInvitations[inv.id] = inv;
    }
    
    // Add dynamic invitations (will override if same id)
    for (final inv in _outgoingInvitations) {
      allInvitations[inv.id] = inv;
    }
    
    // Return sorted by sentAt (newest first)
    return allInvitations.values.toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }
}

