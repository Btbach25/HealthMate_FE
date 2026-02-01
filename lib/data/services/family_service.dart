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
    required String name,
    String? relationship,
    int? age,
    required List<String> sharedMetrics,
  });
  Future<void> acceptInvitation({
    required String invitationId,
    required List<String> sharedMetrics,
  });
  Future<void> declineInvitation({required String invitationId});
  Future<GroupDetails> getGroupDetails({required String groupId});
  Future<void> transferOwnership({required String groupId, required String newOwnerId});
  Future<void> removeMember({required String groupId, required String memberId});
  Future<List<IncomingInvitation>> getIncomingInvitations();
  Future<List<OutgoingInvitation>> getOutgoingInvitations();
}


