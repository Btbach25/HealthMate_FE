import 'package:fe/core/utils/user_id_utils.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/user/user.dart';

/// Danh sách thành viên hiển thị: bù owner nếu BE thiếu, đồng bộ tên/avatar user hiện tại, fallback tên chủ nhóm.
List<FamilyMember> buildEffectiveMembersForGroupDetails({
  required GroupDetails details,
  required User authUser,
  required bool isCurrentUserOwner,
  required bool ownerAlreadyInList,
}) {
  final groupMetricsPlaceholder = details.group.sharedMetrics;
  final out = <FamilyMember>[];

  if (isCurrentUserOwner && !ownerAlreadyInList) {
    out.add(
      FamilyMember(
        id: authUser.id,
        userId: authUser.id,
        groupId: details.group.id,
        name: authUser.name.isNotEmpty ? authUser.name : 'Bạn',
        email: authUser.email,
        age: null,
        relationship: null,
        avatar: authUser.picture,
        healthStatus: HealthStatus.healthy,
        lastUpdated: DateTime.now(),
        healthConditions: const [],
        sharedMetrics: groupMetricsPlaceholder,
        createdAt: DateTime.now(),
      ),
    );
  }

  for (final m in details.members) {
    if (sameUserId(m.userId, authUser.id)) {
      out.add(
        m.copyWith(
          name: authUser.name.isNotEmpty ? authUser.name : 'Bạn',
          email: authUser.email,
          avatar: authUser.picture,
          sharedMetrics:
              m.sharedMetrics.isEmpty ? groupMetricsPlaceholder : m.sharedMetrics,
        ),
      );
    } else {
      final isOwnerWithNoName = sameUserId(m.userId, details.group.ownerId) &&
          (m.name.isEmpty || m.name == 'Thành viên');
      out.add(isOwnerWithNoName ? m.copyWith(name: 'Chủ nhóm') : m);
    }
  }

  return out;
}
