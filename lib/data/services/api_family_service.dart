import 'package:fe/core/utils/metric_selection_helper.dart';
import 'package:fe/data/core/api_client.dart';
import 'package:fe/data/core/api_endpoints.dart';
import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/data/remote/group_api_mapper.dart';
import 'package:fe/data/services/family_service.dart';

/// Implementation [FamilyService] gọi API Groups qua [ApiClient].
/// Path lấy từ [ApiEndpoints], map response qua [GroupApiMapper].
class ApiFamilyService implements FamilyService {
  final ApiClient _apiClient;

  ApiFamilyService({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<FamilyGroupSummary> getFamilyGroups() async {
    try {
      final list = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.groups,
        parser: (data) => data is List ? data : [],
      );
      return GroupApiMapper.toFamilyGroupSummary(list);
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
      final body = <String, dynamic>{'name': name};
      final data = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.groups,
        body: body,
        parser: (d) => d as Map<String, dynamic>,
      );
      final group = GroupApiMapper.toFamilyGroup(data);
      final metricTypes = MetricSelectionHelper.filterMetricTypesForBackend(sharedMetrics);
      if (metricTypes.isNotEmpty) {
        await _apiClient.put<void>(
          ApiEndpoints.groupPermissions(data['id'].toString()),
          body: {'metric_types': metricTypes},
          parser: (_) {},
        );
      }
      return group;
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
      if (body.isNotEmpty) {
        await _apiClient.put<void>(
          ApiEndpoints.groupById(groupId),
          body: body,
          parser: (_) {},
        );
      }
      if (sharedMetrics != null && sharedMetrics.isNotEmpty) {
        final metricTypes = MetricSelectionHelper.filterMetricTypesForBackend(sharedMetrics);
        if (metricTypes.isNotEmpty) {
          await _apiClient.put<void>(
            ApiEndpoints.groupPermissions(groupId),
            body: {'metric_types': metricTypes},
            parser: (_) {},
          );
        }
      }
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
        ApiEndpoints.groupById(groupId),
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

  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  Future<void> leaveGroup({required String groupId}) async {
    final tidied = groupId.trim();
    if (tidied.isEmpty || !_uuidRegex.hasMatch(tidied)) {
      throw UnknownException(
        message: 'Mã nhóm không hợp lệ. Bạn có thể đang dùng dữ liệu thử nghiệm không phải UUID.',
        originalError: null,
      );
    }
    try {
      await _apiClient.delete<void>(
        ApiEndpoints.groupMembersMe(tidied),
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

  /// BE chỉ hỗ trợ {"email":"..."}. Nếu nhập email vào ô User ID, vẫn dùng được.
  @override
  Future<void> inviteMember({
    required String groupId,
    required String email,
    required String name,
    String? relationship,
    int? age,
    required List<String> sharedMetrics,
    String? userId,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedUserId = userId?.trim();
    // BE chỉ nhận email. Nếu User ID chứa @ thì coi là email (nhập nhầm ô).
    final effectiveEmail = trimmedEmail.isNotEmpty
        ? trimmedEmail
        : (trimmedUserId != null &&
                trimmedUserId.isNotEmpty &&
                trimmedUserId.contains('@'))
            ? trimmedUserId
            : '';
    if (effectiveEmail.isEmpty) {
      throw UnknownException(
        message: 'Backend chỉ hỗ trợ mời bằng email. Vui lòng nhập email đã đăng ký vào ô Email.',
        originalError: null,
      );
    }
    try {
      // BE chỉ nhận đúng 1 field: email (InviteMemberRequest). Gửi rõ Content-Type để tránh "invalid request".
      final body = <String, dynamic>{'email': effectiveEmail};
      await _apiClient.post<void>(
        ApiEndpoints.groupMembers(groupId),
        body: body,
        headers: {'Content-Type': 'application/json'},
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
  Future<GroupDetails> getGroupDetails({
    required String groupId,
    FamilyGroup? cachedGroup,
  }) async {
    try {
      final FamilyGroup group;
      if (cachedGroup != null && cachedGroup.id == groupId) {
        group = cachedGroup;
      } else {
        final list = await _apiClient.get<List<dynamic>>(
          ApiEndpoints.groups,
          parser: (data) => data is List ? data : [],
        );
        Map<String, dynamic>? groupMap;
        for (final e in list) {
          if (e is Map<String, dynamic> &&
              (e['id']?.toString() ?? '') == groupId) {
            groupMap = e;
            break;
          }
        }
        if (groupMap == null) {
          throw const NotFoundException(
            message: 'Không tìm thấy nhóm.',
          );
        }
        group = GroupApiMapper.toFamilyGroup(groupMap);
      }
      final membersRaw = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.groupMembers(groupId),
        parser: (data) => data is List ? data : [],
      );
      final members = membersRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => GroupApiMapper.toFamilyMember(e, groupId))
          .toList();
      final groupWithCount = group.copyWith(memberCount: members.length);
      return GroupDetails(group: groupWithCount, members: members);
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnknownException(
        message: 'Lỗi khi tải chi tiết nhóm.',
        originalError: e,
      );
    }
  }

  /// BE: PUT /groups/:id/owner body {"new_owner_id":"..."}.
  @override
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    try {
      await _apiClient.put<void>(
        ApiEndpoints.groupOwner(groupId),
        body: {'new_owner_id': newOwnerId},
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

  /// BE: PUT /groups/:id/members/me body {"status":"accepted"} rồi PUT permissions.
  @override
  Future<void> acceptInvitation({
    required String groupId,
    required List<String> sharedMetrics,
  }) async {
    try {
      await _apiClient.put<void>(
        ApiEndpoints.groupMembersMe(groupId),
        body: {'status': 'accepted'},
        parser: (_) {},
      );
      final metricTypes = MetricSelectionHelper.filterMetricTypesForBackend(sharedMetrics);
      if (metricTypes.isNotEmpty) {
        await _apiClient.put<void>(
          ApiEndpoints.groupPermissions(groupId),
          body: {'metric_types': metricTypes},
          parser: (_) {},
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi chấp nhận lời mời.',
        originalError: e,
      );
    }
  }

  /// BE: PUT /groups/:id/members/me body {"status":"rejected"}.
  @override
  Future<void> declineInvitation({required String groupId}) async {
    try {
      await _apiClient.put<void>(
        ApiEndpoints.groupMembersMe(groupId),
        body: {'status': 'rejected'},
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
      final list = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.groupIncomingInvitations,
        parser: (data) => data is List ? data : [],
      );
      return list
          .whereType<Map<String, dynamic>>()
          .map(IncomingInvitation.fromJson)
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải danh sách lời mời tham gia.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<OutgoingInvitation>> getOutgoingInvitations() async {
    try {
      final list = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.groups,
        parser: (data) => data is List ? data : [],
      );
      final result = <OutgoingInvitation>[];
      for (final g in list) {
        final map = g as Map<String, dynamic>;
        final groupId = map['id']?.toString() ?? '';
        final group = GroupApiMapper.toFamilyGroup(map);
        final membersRaw = await _apiClient.get<List<dynamic>>(
          ApiEndpoints.groupMembers(groupId),
          parser: (data) => data is List ? data : [],
        );
        for (final m in membersRaw) {
          final member = m as Map<String, dynamic>;
          if ((member['status']?.toString() ?? '') != 'pending') continue;
          result.add(GroupApiMapper.toOutgoingInvitation(
            memberJson: member,
            groupId: groupId,
            group: group,
          ));
        }
      }
      return result;
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
        ApiEndpoints.groupMemberById(groupId, memberId),
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
