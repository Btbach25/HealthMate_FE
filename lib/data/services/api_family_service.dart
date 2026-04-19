import 'package:fe/core/utils/metric_selection_helper.dart';
import 'package:fe/data/enums/metric_type.dart';
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

  List<String> _extractGlobalMetricTypesFromPermissions(dynamic rawPermissions) {
    if (rawPermissions is Map<String, dynamic>) {
      final global = rawPermissions['global'];
      if (global is List) {
        return global
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
      }
      return const [];
    }
    final rawList = rawPermissions is List ? rawPermissions : const [];
    final metricTypes = <String>{};
    for (final item in rawList) {
      if (item is! Map<String, dynamic>) continue;
      final metricType = item['metric_type']?.toString() ?? '';
      final sharedWith = item['shared_with_user_id']?.toString();
      if (metricType.isEmpty) continue;
      if (sharedWith == null || sharedWith.isEmpty || sharedWith == 'null') {
        metricTypes.add(metricType);
      }
    }
    return metricTypes.toList();
  }

  List<MetricType> _toMetricTypes(List<String> metricTypes) {
    final parsed = <MetricType>[];
    for (final metric in metricTypes) {
      try {
        parsed.add(MetricType.fromValue(metric));
      } catch (_) {
        // Ignore metric types FE has not mapped yet.
      }
    }
    return parsed;
  }

  List<String> _extractSpecificMetricTypesFromPermissions(
    dynamic rawPermissions,
    String targetUserId,
  ) {
    if (rawPermissions is Map<String, dynamic>) {
      final specific = rawPermissions['specific'];
      if (specific is! List) return const [];
      final metricTypes = <String>{};
      for (final item in specific) {
        if (item is! Map<String, dynamic>) continue;
        final userId = item['user_id']?.toString() ?? '';
        if (userId != targetUserId) continue;
        final metrics = item['metrics'];
        if (metrics is! List) continue;
        for (final metric in metrics) {
          final metricType = metric?.toString() ?? '';
          if (metricType.isNotEmpty) metricTypes.add(metricType);
        }
      }
      return metricTypes.toList();
    }
    final rawList = rawPermissions is List ? rawPermissions : const [];
    final metricTypes = <String>{};
    for (final item in rawList) {
      if (item is! Map<String, dynamic>) continue;
      final metricType = item['metric_type']?.toString() ?? '';
      final sharedWith = item['shared_with_user_id']?.toString() ?? '';
      if (metricType.isEmpty || sharedWith.isEmpty) continue;
      if (sharedWith == targetUserId) {
        metricTypes.add(metricType);
      }
    }
    return metricTypes.toList();
  }

  @override
  Future<FamilyGroupSummary> getFamilyGroups() async {
    try {
      final list = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.groups,
        parser: (data) => data is List ? data : [],
      );
      final summary = GroupApiMapper.toFamilyGroupSummary(list);

      final hydratedGroups = await Future.wait(
        summary.groups.map((group) async {
          try {
            final permissionsRaw = await _apiClient.get<dynamic>(
              ApiEndpoints.groupPermissions(group.id),
              parser: (data) => data,
            );
            final globalMetricTypes =
                _extractGlobalMetricTypesFromPermissions(permissionsRaw);
            final parsed = _toMetricTypes(globalMetricTypes);
            if (parsed.isEmpty) return group;
            return group.copyWith(sharedMetrics: parsed);
          } catch (_) {
            // Some roles/groups may not allow reading permissions.
            // Keep existing mapped metrics as fallback.
            return group;
          }
        }),
      );

      return summary.copyWith(groups: hydratedGroups);
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
      var group = GroupApiMapper.toFamilyGroup(data);
      final metricTypes = MetricSelectionHelper.filterMetricTypesForBackend(sharedMetrics);
      if (metricTypes.isNotEmpty) {
        await _apiClient.put<void>(
          ApiEndpoints.groupPermissions(data['id'].toString()),
          body: {'metric_types': metricTypes},
          parser: (_) {},
        );
        // POST /groups thường chưa phản ánh permissions vừa PUT — merge để list/detail khớp ngay, tránh cảm giác “chậm / sai” tới lần GET sau.
        final parsed = <MetricType>[];
        for (final s in metricTypes) {
          try {
            parsed.add(MetricType.fromValue(s));
          } catch (_) {}
        }
        if (parsed.isNotEmpty) {
          group = group.copyWith(sharedMetrics: parsed);
        }
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
      var permissionsUpdated = false;
      if (sharedMetrics != null && sharedMetrics.isNotEmpty) {
        final metricTypes = MetricSelectionHelper.filterMetricTypesForBackend(sharedMetrics);
        if (metricTypes.isNotEmpty) {
          await _apiClient.put<void>(
            ApiEndpoints.groupPermissions(groupId),
            body: {'metric_types': metricTypes},
            parser: (_) {},
          );
          permissionsUpdated = true;
        }
      }
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (body.isNotEmpty) {
        try {
          await _apiClient.put<void>(
            ApiEndpoints.groupById(groupId),
            body: body,
            parser: (_) {},
          );
        } on ServerException catch (e) {
          if (permissionsUpdated) {
            throw UnknownException(
              message:
                  'Đã lưu quyền chia sẻ, nhưng đổi tên nhóm đang lỗi phía máy chủ. Vui lòng thử đổi tên lại sau.',
              originalError: e,
            );
          }
          rethrow;
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
        message: 'Mã nhóm không hợp lệ. Hãy mở lại nhóm từ danh sách hoặc đăng nhập lại.',
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
    String name = '',
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

      // FE-side effective permissions:
      // - BE may return mixed global + specific rows.
      // - We derive global set once, then compute per-member effective set.
      final globalPermissionsRaw = await _apiClient.get<dynamic>(
        ApiEndpoints.groupPermissions(groupId),
        parser: (data) => data,
      );
      final globalMetricTypes =
          _extractGlobalMetricTypesFromPermissions(globalPermissionsRaw);
      final globalMetricTypeSet = globalMetricTypes.toSet();
      final globalMetricsParsed = _toMetricTypes(globalMetricTypes);

      final effectiveMembers = await Future.wait(
        members.map((member) async {
          final memberPermissionsRaw = await _apiClient.get<dynamic>(
            ApiEndpoints.groupPermissions(groupId),
            queryParameters: {'target_user_id': member.userId},
            parser: (data) => data,
          );

          final memberGlobalMetricTypes =
              _extractGlobalMetricTypesFromPermissions(memberPermissionsRaw);
          final effectiveGlobalSet = memberGlobalMetricTypes.isNotEmpty
              ? memberGlobalMetricTypes.toSet()
              : globalMetricTypeSet;

          final specificMetricTypes = _extractSpecificMetricTypesFromPermissions(
            memberPermissionsRaw,
            member.userId,
          ).toSet();

          // Default-open mode:
          // - No specific rules for this member => inherits global.
          // - Has specific rules => effective = global ∩ specific.
          final effectiveMetricTypes = specificMetricTypes.isEmpty
              ? effectiveGlobalSet
              : effectiveGlobalSet.intersection(specificMetricTypes);

          final parsed = _toMetricTypes(effectiveMetricTypes.toList());
          return member.copyWith(
            sharedMetrics: parsed,
          );
        }),
      );

      final groupWithCount = group.copyWith(
        memberCount: members.length,
        sharedMetrics:
            globalMetricsParsed.isNotEmpty ? globalMetricsParsed : group.sharedMetrics,
      );
      return GroupDetails(group: groupWithCount, members: effectiveMembers);
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

  /// BE: GET /groups chỉ trả members accepted; lời mời pending lấy từ GET /groups/:id/invitations.
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
        final group = GroupApiMapper.toFamilyGroup(map);
        final invitationsRaw = await _apiClient.get<List<dynamic>>(
          ApiEndpoints.groupInvitations(group.id),
          parser: (data) => data is List ? data : [],
        );
        for (final inv in invitationsRaw) {
          if (inv is! Map<String, dynamic>) continue;
          result.add(GroupApiMapper.sentInvitationToOutgoing(
            json: inv,
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

  @override
  Future<void> updateMemberPermissions({
    required String groupId,
    required String memberId,
    required List<String> sharedMetrics,
  }) async {
    try {
      final metricTypes =
          MetricSelectionHelper.filterMetricTypesForBackend(sharedMetrics);
      await _apiClient.put<void>(
        ApiEndpoints.groupPermissions(groupId),
        body: {
          'target_user_id': memberId,
          'metric_types': metricTypes,
        },
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi cập nhật quyền chia sẻ cho thành viên.',
        originalError: e,
      );
    }
  }
}
