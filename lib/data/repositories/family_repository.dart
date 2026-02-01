import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/data/services/family_service.dart';

/// Repository layer that abstracts data sources
/// Currently uses FamilyService (can be Mock or API implementation)
/// 
/// This layer provides:
/// - Error handling and transformation
/// - Caching (can be added later)
/// - Data transformation
class FamilyRepository {
  final FamilyService _familyService;

  FamilyRepository({required FamilyService familyService})
      : _familyService = familyService;

  Future<FamilyGroupSummary> getFamilyGroups() async {
    try {
      return await _familyService.getFamilyGroups();
    } on ApiException {
      // Re-throw ApiException as-is (already has proper error messages)
      rethrow;
    } catch (e) {
      // Wrap unexpected errors
      throw UnknownException(
        message: 'Lỗi khi tải danh sách nhóm gia đình.',
        originalError: e,
      );
    }
  }

  Future<FamilyGroup> createGroup({
    required String name,
    required List<String> sharedMetrics,
  }) async {
    try {
      return await _familyService.createGroup(
        name: name,
        sharedMetrics: sharedMetrics,
      );
    } catch (e) {
      print('Error in FamilyRepository.createGroup: $e');
      rethrow;
    }
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    List<String>? sharedMetrics,
  }) async {
    try {
      await _familyService.updateGroup(
        groupId: groupId,
        name: name,
        sharedMetrics: sharedMetrics,
      );
    } catch (e) {
      print('Error in FamilyRepository.updateGroup: $e');
      rethrow;
    }
  }

  Future<void> deleteGroup({required String groupId}) async {
    try {
      await _familyService.deleteGroup(groupId: groupId);
    } catch (e) {
      print('Error in FamilyRepository.deleteGroup: $e');
      rethrow;
    }
  }

  Future<void> leaveGroup({required String groupId}) async {
    try {
      await _familyService.leaveGroup(groupId: groupId);
    } catch (e) {
      print('Error in FamilyRepository.leaveGroup: $e');
      rethrow;
    }
  }

  Future<void> inviteMember({
    required String groupId,
    required String email,
    required String name,
    String? relationship,
    int? age,
    required List<String> sharedMetrics,
  }) async {
    try {
      await _familyService.inviteMember(
        groupId: groupId,
        email: email,
        name: name,
        relationship: relationship,
        age: age,
        sharedMetrics: sharedMetrics,
      );
    } catch (e) {
      print('Error in FamilyRepository.inviteMember: $e');
      rethrow;
    }
  }

  Future<GroupDetails> getGroupDetails({required String groupId}) async {
    try {
      return await _familyService.getGroupDetails(groupId: groupId);
    } catch (e) {
      print('Error in FamilyRepository.getGroupDetails: $e');
      rethrow;
    }
  }

  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    try {
      await _familyService.transferOwnership(
        groupId: groupId,
        newOwnerId: newOwnerId,
      );
    } catch (e) {
      print('Error in FamilyRepository.transferOwnership: $e');
      rethrow;
    }
  }

  Future<void> acceptInvitation({
    required String invitationId,
    required List<String> sharedMetrics,
  }) async {
    try {
      await _familyService.acceptInvitation(
        invitationId: invitationId,
        sharedMetrics: sharedMetrics,
      );
    } catch (e) {
      print('Error in FamilyRepository.acceptInvitation: $e');
      rethrow;
    }
  }

  Future<void> declineInvitation({required String invitationId}) async {
    try {
      await _familyService.declineInvitation(invitationId: invitationId);
    } catch (e) {
      print('Error in FamilyRepository.declineInvitation: $e');
      rethrow;
    }
  }

  Future<List<IncomingInvitation>> getIncomingInvitations() async {
    try {
      return await _familyService.getIncomingInvitations();
    } catch (e) {
      print('Error in FamilyRepository.getIncomingInvitations: $e');
      rethrow;
    }
  }

  Future<List<OutgoingInvitation>> getOutgoingInvitations() async {
    try {
      return await _familyService.getOutgoingInvitations();
    } catch (e) {
      print('Error in FamilyRepository.getOutgoingInvitations: $e');
      rethrow;
    }
  }

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    try {
      await _familyService.removeMember(
        groupId: groupId,
        memberId: memberId,
      );
    } catch (e) {
      print('Error in FamilyRepository.removeMember: $e');
      rethrow;
    }
  }
}


