import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/data/services/family_service.dart';

/// Cổng vào duy nhất của tầng UI cho nghiệp vụ nhóm gia đình; uỷ quyền toàn
/// bộ cho [FamilyService].
///
/// Quy ước lỗi: [getFamilyGroups] bọc lỗi lạ thành [UnknownException] để UI
/// luôn có message tiếng Việt hiển thị được; các method còn lại `rethrow`
/// nguyên trạng vì caller đã tự xử lý.
///
/// Đổi nguồn dữ liệu bằng cách đăng ký một [FamilyService] khác ở
/// `lib/core/di/app_dependencies.dart` (composition root).
class FamilyRepository {
  final FamilyService _familyService;

  FamilyRepository({required FamilyService familyService})
      : _familyService = familyService;

  Future<FamilyGroupSummary> getFamilyGroups() async {
    try {
      return await _familyService.getFamilyGroups();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải danh sách nhóm gia đình.',
        originalError: e,
      );
    }
  }

  Future<FamilyGroup> createGroup({
    required String name,
    required List<String> sharedMetrics,
    bool enableMedicationReminderShare = false,
  }) =>
      _familyService.createGroup(
        name: name,
        sharedMetrics: sharedMetrics,
        enableMedicationReminderShare: enableMedicationReminderShare,
      );

  Future<void> updateGroup({
    required String groupId,
    String? name,
    List<String>? sharedMetrics,
    bool? enableMedicationReminderShare,
  }) =>
      _familyService.updateGroup(
        groupId: groupId,
        name: name,
        sharedMetrics: sharedMetrics,
        enableMedicationReminderShare: enableMedicationReminderShare,
      );

  Future<void> deleteGroup({required String groupId}) =>
      _familyService.deleteGroup(groupId: groupId);

  Future<void> leaveGroup({required String groupId}) =>
      _familyService.leaveGroup(groupId: groupId);

  Future<void> inviteMember({
    required String groupId,
    required String email,
    String name = '',
    String? relationship,
    int? age,
    required List<String> sharedMetrics,
    String? userId,
  }) =>
      _familyService.inviteMember(
        groupId: groupId,
        email: email,
        name: name,
        relationship: relationship,
        age: age,
        sharedMetrics: sharedMetrics,
        userId: userId,
      );

  Future<GroupDetails> getGroupDetails({
    required String groupId,
    FamilyGroup? cachedGroup,
  }) =>
      _familyService.getGroupDetails(
        groupId: groupId,
        cachedGroup: cachedGroup,
      );

  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) =>
      _familyService.transferOwnership(
        groupId: groupId,
        newOwnerId: newOwnerId,
      );

  Future<void> acceptInvitation({
    required String groupId,
    required List<String> sharedMetrics,
  }) =>
      _familyService.acceptInvitation(
        groupId: groupId,
        sharedMetrics: sharedMetrics,
      );

  Future<void> declineInvitation({required String groupId}) =>
      _familyService.declineInvitation(groupId: groupId);

  Future<List<IncomingInvitation>> getIncomingInvitations() =>
      _familyService.getIncomingInvitations();

  Future<List<OutgoingInvitation>> getOutgoingInvitations() =>
      _familyService.getOutgoingInvitations();

  Future<List<FamilyMember>> getGroupMembersForInvitee({
    required String groupId,
  }) =>
      _familyService.getGroupMembersForInvitee(groupId: groupId);

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) =>
      _familyService.removeMember(groupId: groupId, memberId: memberId);

  Future<void> updateMemberPermissions({
    required String groupId,
    required String memberId,
    required List<String> sharedMetrics,
    bool? allowMedicationReminderShare,
  }) =>
      _familyService.updateMemberPermissions(
        groupId: groupId,
        memberId: memberId,
        sharedMetrics: sharedMetrics,
        allowMedicationReminderShare: allowMedicationReminderShare,
      );

  Future<List<OutgoingInvitation>> getPendingApprovals({
    required String groupId,
  }) =>
      _familyService.getPendingApprovals(groupId: groupId);

  Future<void> approveJoinRequest({
    required String groupId,
    required String memberId,
  }) =>
      _familyService.approveJoinRequest(groupId: groupId, memberId: memberId);

  Future<void> rejectJoinRequest({
    required String groupId,
    required String memberId,
  }) =>
      _familyService.rejectJoinRequest(groupId: groupId, memberId: memberId);

  Future<void> updateMySharing({
    required String groupId,
    required List<String> sharedMetrics,
  }) =>
      _familyService.updateMySharing(
        groupId: groupId,
        sharedMetrics: sharedMetrics,
      );

  Future<List<String>> getMySpecificMetricsForMember({
    required String groupId,
    required String memberId,
  }) =>
      _familyService.getMySpecificMetricsForMember(
        groupId: groupId,
        memberId: memberId,
      );
}
