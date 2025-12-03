import 'package:equatable/equatable.dart';
import 'package:fe/data/models/group/family_group.dart';

class FamilyGroupSummary extends Equatable {
  final int groupsJoined;
  final int pendingInvitations;
  final List<FamilyGroup> groups;

  const FamilyGroupSummary({
    required this.groupsJoined,
    required this.pendingInvitations,
    required this.groups,
  });

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


