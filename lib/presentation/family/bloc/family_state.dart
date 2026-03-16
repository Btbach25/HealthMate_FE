part of 'family_bloc.dart';

enum FamilyStatus {
  initial,
  loading,
  loaded,
  error,
  creatingGroup,
  groupCreated,
  groupDetailsLoaded,
  memberInvited,
  memberRemoved,
  ownershipTransferred,
  groupLeft,
  invitationsLoaded,
  invitationAccepted,
  invitationDeclined,
  groupUpdated,
}

const _familyStateUnset = Object();

class FamilyState extends Equatable {
  final FamilyStatus status;
  final FamilyGroupSummary summary;
  final String? errorMessage;
  /// True khi lỗi 401 (phiên hết hạn) → nút "Thử lại" chuyển sang đăng nhập.
  final bool isSessionExpired;
  final String? createdGroupName;
  final GroupDetails? groupDetails;
  final String? currentGroupId;
  final List<IncomingInvitation> incomingInvitations;
  final List<OutgoingInvitation> outgoingInvitations;
  /// FE-only: các group đã rời/xóa cục bộ, dùng để filter kết quả fetch trễ.
  final Set<String> hiddenGroupIds;

  const FamilyState({
    required this.status,
    required this.summary,
    this.errorMessage,
    this.isSessionExpired = false,
    this.createdGroupName,
    this.groupDetails,
    this.currentGroupId,
    this.incomingInvitations = const [],
    this.outgoingInvitations = const [],
    this.hiddenGroupIds = const <String>{},
  });

  factory FamilyState.initial() {
    return const FamilyState(
      status: FamilyStatus.initial,
      summary: FamilyGroupSummary(
        groupsJoined: 0,
        pendingInvitations: 0,
        groups: [],
      ),
      currentGroupId: null,
      incomingInvitations: [],
      outgoingInvitations: [],
      hiddenGroupIds: <String>{},
    );
  }

  FamilyState copyWith({
    FamilyStatus? status,
    FamilyGroupSummary? summary,
    Object? errorMessage = _familyStateUnset,
    Object? isSessionExpired = _familyStateUnset,
    Object? createdGroupName = _familyStateUnset,
    Object? groupDetails = _familyStateUnset,
    Object? currentGroupId = _familyStateUnset,
    Object? incomingInvitations = _familyStateUnset,
    Object? outgoingInvitations = _familyStateUnset,
    Object? hiddenGroupIds = _familyStateUnset,
  }) {
    return FamilyState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: identical(errorMessage, _familyStateUnset)
          ? this.errorMessage
          : errorMessage as String?,
      isSessionExpired: identical(isSessionExpired, _familyStateUnset)
          ? this.isSessionExpired
          : isSessionExpired as bool,
      createdGroupName: identical(createdGroupName, _familyStateUnset)
          ? this.createdGroupName
          : createdGroupName as String?,
      groupDetails: identical(groupDetails, _familyStateUnset)
          ? this.groupDetails
          : groupDetails as GroupDetails?,
      currentGroupId: identical(currentGroupId, _familyStateUnset)
          ? this.currentGroupId
          : currentGroupId as String?,
      incomingInvitations: identical(incomingInvitations, _familyStateUnset)
          ? this.incomingInvitations
          : incomingInvitations as List<IncomingInvitation>,
      outgoingInvitations: identical(outgoingInvitations, _familyStateUnset)
          ? this.outgoingInvitations
          : outgoingInvitations as List<OutgoingInvitation>,
      hiddenGroupIds: identical(hiddenGroupIds, _familyStateUnset)
          ? this.hiddenGroupIds
          : hiddenGroupIds as Set<String>,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        errorMessage,
        isSessionExpired,
        createdGroupName,
        groupDetails,
        currentGroupId,
        incomingInvitations,
        outgoingInvitations,
        hiddenGroupIds,
      ];
}


