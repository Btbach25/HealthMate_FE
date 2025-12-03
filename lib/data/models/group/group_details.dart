import 'package:equatable/equatable.dart';
import 'package:fe/data/enums/group_member_role.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_member.dart';

class GroupDetails extends Equatable {
  final FamilyGroup group;
  final List<FamilyMember> members;

  const GroupDetails({
    required this.group,
    required this.members,
  });

  factory GroupDetails.empty() {
    return GroupDetails(
      group: FamilyGroup(
        id: '',
        name: '',
        memberCount: 0,
        userRole: GroupMemberRole.member,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sharedMetrics: const [],
        ownerId: '',
      ),
      members: const [],
    );
  }

  GroupDetails copyWith({
    FamilyGroup? group,
    List<FamilyMember>? members,
  }) {
    return GroupDetails(
      group: group ?? this.group,
      members: members ?? this.members,
    );
  }

  @override
  List<Object?> get props => [group, members];
}

