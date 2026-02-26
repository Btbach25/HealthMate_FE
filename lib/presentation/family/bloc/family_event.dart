part of 'family_bloc.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

class FetchFamilyGroups extends FamilyEvent {
  const FetchFamilyGroups();
}

class CreateGroup extends FamilyEvent {
  final String name;
  final List<String> sharedMetrics;

  const CreateGroup({
    required this.name,
    required this.sharedMetrics,
  });

  @override
  List<Object?> get props => [name, sharedMetrics];
}

class UpdateGroup extends FamilyEvent {
  final String groupId;
  final String? name;
  final List<String>? sharedMetrics;

  const UpdateGroup({
    required this.groupId,
    this.name,
    this.sharedMetrics,
  });

  @override
  List<Object?> get props => [groupId, name, sharedMetrics];
}

class DeleteGroup extends FamilyEvent {
  final String groupId;

  const DeleteGroup({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class LeaveGroup extends FamilyEvent {
  final String groupId;

  const LeaveGroup({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class FetchGroupDetails extends FamilyEvent {
  final String groupId;

  const FetchGroupDetails({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class InviteMember extends FamilyEvent {
  final String groupId;
  final String email;
  final String name;
  final String? relationship;
  final int? age;
  final List<String> sharedMetrics;

  const InviteMember({
    required this.groupId,
    required this.email,
    required this.name,
    this.relationship,
    this.age,
    required this.sharedMetrics,
  });

  @override
  List<Object?> get props => [groupId, email, name, relationship, age, sharedMetrics];
}

class TransferOwnership extends FamilyEvent {
  final String groupId;
  final String newOwnerId;

  const TransferOwnership({
    required this.groupId,
    required this.newOwnerId,
  });

  @override
  List<Object?> get props => [groupId, newOwnerId];
}

class FetchIncomingInvitations extends FamilyEvent {
  const FetchIncomingInvitations();
}

class FetchOutgoingInvitations extends FamilyEvent {
  const FetchOutgoingInvitations();
}

class AcceptInvitation extends FamilyEvent {
  final String invitationId;
  final List<String> sharedMetrics;

  const AcceptInvitation({
    required this.invitationId,
    required this.sharedMetrics,
  });

  @override
  List<Object?> get props => [invitationId, sharedMetrics];
}

class DeclineInvitation extends FamilyEvent {
  final String invitationId;

  const DeclineInvitation({required this.invitationId});

  @override
  List<Object?> get props => [invitationId];
}

class RemoveMember extends FamilyEvent {
  final String groupId;
  final String memberId;

  const RemoveMember({
    required this.groupId,
    required this.memberId,
  });

  @override
  List<Object?> get props => [groupId, memberId];
}


