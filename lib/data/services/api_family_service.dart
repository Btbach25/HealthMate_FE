import 'package:fe/data/core/api_client.dart';
import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/data/services/family_service.dart';

/// Real API implementation of FamilyService
/// This class implements the FamilyService interface using actual API calls
/// 
/// Usage:
/// ```dart
/// final apiClient = ApiClientImpl(baseUrl: 'https://api.example.com', ...);
/// final familyService = ApiFamilyService(apiClient: apiClient);
/// final repository = FamilyRepository(familyService: familyService);
/// ```
class ApiFamilyService implements FamilyService {
  final ApiClient _apiClient;

  ApiFamilyService({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<FamilyGroupSummary> getFamilyGroups() async {
    try {
      return await _apiClient.get<FamilyGroupSummary>(
        '/api/family/groups',
        parser: (data) => FamilyGroupSummary.fromJson(data as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải danh sách nhóm gia đình.',
        originalError: e,
      );
    }
  }

  @override
  Future<FamilyGroup> createGroup({
    required String name,
    required List<String> sharedMetrics,
  }) async {
    try {
      return await _apiClient.post<FamilyGroup>(
        '/api/family/groups',
        body: {
          'name': name,
          'sharedMetrics': sharedMetrics,
        },
        parser: (data) => FamilyGroup.fromJson(data as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tạo nhóm gia đình.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateGroup({
    required String groupId,
    String? name,
    List<String>? sharedMetrics,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (sharedMetrics != null) body['sharedMetrics'] = sharedMetrics;

      await _apiClient.put<void>(
        '/api/family/groups/$groupId',
        body: body,
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi cập nhật nhóm gia đình.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteGroup({required String groupId}) async {
    try {
      await _apiClient.delete<void>(
        '/api/family/groups/$groupId',
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi xóa nhóm gia đình.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> leaveGroup({required String groupId}) async {
    try {
      await _apiClient.post<void>(
        '/api/family/groups/$groupId/leave',
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi rời nhóm gia đình.',
        originalError: e,
      );
    }
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
    try {
      final body = <String, dynamic>{
        'email': email,
        'name': name,
        'sharedMetrics': sharedMetrics,
      };
      if (relationship != null) body['relationship'] = relationship;
      if (age != null) body['age'] = age;

      await _apiClient.post<void>(
        '/api/family/groups/$groupId/invitations',
        body: body,
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi gửi lời mời thành viên.',
        originalError: e,
      );
    }
  }

  @override
  Future<GroupDetails> getGroupDetails({required String groupId}) async {
    try {
      return await _apiClient.get<GroupDetails>(
        '/api/family/groups/$groupId',
        parser: (data) => GroupDetails.fromJson(data as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải chi tiết nhóm.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    try {
      await _apiClient.post<void>(
        '/api/family/groups/$groupId/transfer-ownership',
        body: {'newOwnerId': newOwnerId},
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi chuyển quyền sở hữu nhóm.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> acceptInvitation({
    required String invitationId,
    required List<String> sharedMetrics,
  }) async {
    try {
      await _apiClient.post<void>(
        '/api/family/invitations/$invitationId/accept',
        body: {'sharedMetrics': sharedMetrics},
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi chấp nhận lời mời.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> declineInvitation({required String invitationId}) async {
    try {
      await _apiClient.post<void>(
        '/api/family/invitations/$invitationId/decline',
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi từ chối lời mời.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<IncomingInvitation>> getIncomingInvitations() async {
    try {
      return await _apiClient.get<List<IncomingInvitation>>(
        '/api/family/invitations/incoming',
        parser: (data) {
          if (data is List) {
            return data
                .map((item) => IncomingInvitation.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải danh sách lời mời đến.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<OutgoingInvitation>> getOutgoingInvitations() async {
    try {
      return await _apiClient.get<List<OutgoingInvitation>>(
        '/api/family/invitations/outgoing',
        parser: (data) {
          if (data is List) {
            return data
                .map((item) => OutgoingInvitation.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải danh sách lời mời đã gửi.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    try {
      await _apiClient.delete<void>(
        '/api/family/groups/$groupId/members/$memberId',
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi xóa thành viên khỏi nhóm.',
        originalError: e,
      );
    }
  }
}

