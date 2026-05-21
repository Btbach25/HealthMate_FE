part of 'family_bloc.dart';

enum FamilyStatus {
  initial,
  loading,
  loaded,
  invitationPreviewLoading,
  invitationPreviewLoaded,
  error,
  creatingGroup,
  groupCreated,
  groupDetailsLoaded,
  memberInvited,
  memberRemoved,
  memberPermissionsUpdated,
  ownershipTransferred,
  groupLeft,
  invitationsLoaded,
  invitationAccepted,
  invitationDeclined,
  groupUpdated,
  // Owner duyệt/từ chối yêu cầu tham gia. [BE-REQ-01] [BE-REQ-02]
  joinRequestApproved,
  joinRequestRejected,
  mySharingUpdated,
  // Bước 1 tạo nhóm: POST /groups thành công, chờ bước 2 cài đặt chia sẻ.
  groupNameCreated,
}

const _familyStateUnset = Object();

class FamilyState extends Equatable {
  final FamilyStatus status;
  final FamilyGroupSummary summary;
  final String? errorMessage;
  /// True khi lỗi 401 (phiên hết hạn) → nút "Thử lại" chuyển sang đăng nhập.
  final bool isSessionExpired;
  final String? createdGroupName;
  /// ID nhóm vừa tạo (bước 1 của 2-step create flow). Null nếu chưa tạo.
  final String? createdGroupId;
  final GroupDetails? groupDetails;
  final String? currentGroupId;
  final List<IncomingInvitation> incomingInvitations;
  final List<OutgoingInvitation> outgoingInvitations;
  /// Owner only: thành viên đang chờ chủ nhóm duyệt (từ GET /groups/:id/pending-approvals).
  final List<OutgoingInvitation> pendingApprovals;
  final GroupDetails? invitationPreviewDetails;
  final String? invitationPreviewGroupId;
  /// FE-only: các group đã rời/xóa cục bộ, dùng để filter kết quả fetch trễ.
  final Set<String> hiddenGroupIds;

  const FamilyState({
    required this.status,
    required this.summary,
    this.errorMessage,
    this.isSessionExpired = false,
    this.createdGroupName,
    this.createdGroupId,
    this.groupDetails,
    this.currentGroupId,
    this.incomingInvitations = const [],
    this.outgoingInvitations = const [],
    this.pendingApprovals = const [],
    this.invitationPreviewDetails,
    this.invitationPreviewGroupId,
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
      pendingApprovals: [],
      invitationPreviewDetails: null,
      invitationPreviewGroupId: null,
      hiddenGroupIds: <String>{},
    );
  }

  FamilyState copyWith({
    FamilyStatus? status,
    FamilyGroupSummary? summary,
    Object? errorMessage = _familyStateUnset,
    Object? isSessionExpired = _familyStateUnset,
    Object? createdGroupName = _familyStateUnset,
    Object? createdGroupId = _familyStateUnset,
    Object? groupDetails = _familyStateUnset,
    Object? currentGroupId = _familyStateUnset,
    Object? incomingInvitations = _familyStateUnset,
    Object? outgoingInvitations = _familyStateUnset,
    Object? pendingApprovals = _familyStateUnset,
    Object? invitationPreviewDetails = _familyStateUnset,
    Object? invitationPreviewGroupId = _familyStateUnset,
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
      createdGroupId: identical(createdGroupId, _familyStateUnset)
          ? this.createdGroupId
          : createdGroupId as String?,
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
      pendingApprovals: identical(pendingApprovals, _familyStateUnset)
          ? this.pendingApprovals
          : pendingApprovals as List<OutgoingInvitation>,
      invitationPreviewDetails:
          identical(invitationPreviewDetails, _familyStateUnset)
              ? this.invitationPreviewDetails
              : invitationPreviewDetails as GroupDetails?,
      invitationPreviewGroupId:
          identical(invitationPreviewGroupId, _familyStateUnset)
              ? this.invitationPreviewGroupId
              : invitationPreviewGroupId as String?,
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
        createdGroupId,
        groupDetails,
        currentGroupId,
        incomingInvitations,
        outgoingInvitations,
        pendingApprovals,
        invitationPreviewDetails,
        invitationPreviewGroupId,
        hiddenGroupIds,
      ];
}


