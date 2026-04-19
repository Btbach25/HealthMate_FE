import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';

abstract class FamilyService {
  Future<FamilyGroupSummary> getFamilyGroups();
  Future<FamilyGroup> createGroup({required String name, required List<String> sharedMetrics});
  Future<void> updateGroup({required String groupId, String? name, List<String>? sharedMetrics});
  Future<void> deleteGroup({required String groupId});
  Future<void> leaveGroup({required String groupId});
  Future<void> inviteMember({
    required String groupId,
    required String email,
    String name = '',
    String? relationship,
    int? age,
    required List<String> sharedMetrics,
    /// BE origin/main: mời bằng email. userId chỉ dùng cho mock nếu cần.
    String? userId,
  });
  /// BE: PUT /groups/:id/members/me body {"status":"accepted"} rồi PUT permissions.
  Future<void> acceptInvitation({
    required String groupId,
    required List<String> sharedMetrics,
  });
  /// BE: PUT /groups/:id/members/me body {"status":"rejected"}.
  Future<void> declineInvitation({required String groupId});
  /// [cachedGroup]: nếu có (đã có từ danh sách nhóm), chỉ gọi GET /groups/:id/members, bỏ qua GET /groups → mở chi tiết nhanh hơn.
  Future<GroupDetails> getGroupDetails({required String groupId, FamilyGroup? cachedGroup});
  Future<void> transferOwnership({required String groupId, required String newOwnerId});
  Future<void> removeMember({required String groupId, required String memberId});
  Future<void> updateMemberPermissions({
    required String groupId,
    required String memberId,
    required List<String> sharedMetrics,
  });
  Future<List<IncomingInvitation>> getIncomingInvitations();
  Future<List<OutgoingInvitation>> getOutgoingInvitations();
}


