import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/converter.dart';
import 'package:fe/data/models/group/family_group.dart';

/// Kết quả `GET /groups/` sau khi FE tách thành nhóm tôi sở hữu và nhóm tôi
/// tham gia, phục vụ trang danh sách nhóm.
class FamilyGroupSummary extends Equatable {
  final int groupsJoined;
  final int pendingInvitations;
  final List<FamilyGroup> groups;

  const FamilyGroupSummary({
    required this.groupsJoined,
    required this.pendingInvitations,
    required this.groups,
  });

  factory FamilyGroupSummary.fromJson(Map<String, dynamic> json) {
    return FamilyGroupSummary(
      groupsJoined: cvToInt(json['groups_joined'] ?? 0),
      pendingInvitations: cvToInt(json['pending_invitations'] ?? 0),
      groups: cvToList(
        json['groups'],
        (e) => FamilyGroup.fromJson(e as Map<String, dynamic>),
      ),
    );
  }

  factory FamilyGroupSummary.empty() {
    return const FamilyGroupSummary(
      groupsJoined: 0,
      pendingInvitations: 0,
      groups: [],
    );
  }

  FamilyGroupSummary copyWith({
    int? groupsJoined,
    int? pendingInvitations,
    List<FamilyGroup>? groups,
  }) {
    return FamilyGroupSummary(
      groupsJoined: groupsJoined ?? this.groupsJoined,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      groups: groups ?? this.groups,
    );
  }

  @override
  List<Object?> get props => [groupsJoined, pendingInvitations, groups];
}
