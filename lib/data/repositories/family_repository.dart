import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/data/services/family_service.dart';

/// Repository layer that abstracts data sources.
/// Wraps unexpected errors into [UnknownException] for getFamilyGroups;
/// all other methods simply rethrow.
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
  }) =>
      _familyService.createGroup(name: name, sharedMetrics: sharedMetrics);

  Future<void> updateGroup({
    required String groupId,
    String? name,
    List<String>? sharedMetrics,
  }) =>
      _familyService.updateGroup(
        groupId: groupId,
        name: name,
        sharedMetrics: sharedMetrics,
      );

  Future<void> deleteGroup({required String groupId}) =>
      _familyService.deleteGroup(groupId: groupId);

  Future<void> leaveGroup({required String groupId}) =>
      _familyService.leaveGroup(groupId: groupId);

  Future<void> inviteMember({
    required String groupId,
    required String email,
    required String name,
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

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) =>
      _familyService.removeMember(groupId: groupId, memberId: memberId);
}
