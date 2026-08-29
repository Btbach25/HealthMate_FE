import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';

/// Hợp đồng cho toàn bộ nghiệp vụ nhóm gia đình: tạo/sửa/xoá nhóm, mời và
/// duyệt thành viên, chuyển quyền chủ nhóm, và cấu hình quyền chia sẻ chỉ số.
///
/// Ánh xạ 1-1 với nhóm endpoint `/groups/...` của backend (xem
/// `ApiEndpoints` và `API_DOC.md`).
///
/// Muốn đổi nguồn dữ liệu (mock / API khác), implement lại interface này rồi
/// đăng ký implementation ở `lib/core/di/app_dependencies.dart` (composition root).
abstract class FamilyService {
  Future<FamilyGroupSummary> getFamilyGroups();
  Future<FamilyGroup> createGroup({
    required String name,
    required List<String> sharedMetrics,
    bool enableMedicationReminderShare = false,
  });
  Future<void> updateGroup({
    required String groupId,
    String? name,
    List<String>? sharedMetrics,
    bool? enableMedicationReminderShare,
  });
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
    bool? allowMedicationReminderShare,
  });
  Future<List<IncomingInvitation>> getIncomingInvitations();
  Future<List<OutgoingInvitation>> getOutgoingInvitations();
  /// Lấy danh sách thành viên cho người được mời (chưa accept). BE cho phép gọi GET /groups/:id/members.
  Future<List<FamilyMember>> getGroupMembersForInvitee({required String groupId});

  /// Owner only: GET /groups/:id/pending-approvals
  Future<List<OutgoingInvitation>> getPendingApprovals({required String groupId});

  /// Owner only: POST /groups/:id/approve/:memberId
  Future<void> approveJoinRequest({
    required String groupId,
    required String memberId,
  });

  /// Owner only: POST /groups/:id/reject-approval/:memberId
  Future<void> rejectJoinRequest({
    required String groupId,
    required String memberId,
  });

  /// PUT /groups/:id/permissions without target_user_id.
  /// Updates the current user's own global sharing metrics.
  Future<void> updateMySharing({
    required String groupId,
    required List<String> sharedMetrics,
  });

  /// GET /groups/:id/permissions?target_user_id=memberId — parse specific rows for memberId.
  /// Returns metric type strings set specifically for that member (excluding access_control).
  /// Empty list = no specific rules (caller should pre-select all global metrics).
  Future<List<String>> getMySpecificMetricsForMember({
    required String groupId,
    required String memberId,
  });
}


