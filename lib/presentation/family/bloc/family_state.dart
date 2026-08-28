part of 'family_bloc.dart';

/// Trạng thái hiện tại của [FamilyBloc].
///
/// Chỉ có MỘT biến status cho cả miền nhóm gia đình, nên listener của một nhóm
/// cụ thể phải đối chiếu thêm `currentGroupId` / `invitationPreviewGroupId`
/// trước khi phản ứng. Xem bảng event -> status ở doc của [FamilyBloc].
enum FamilyStatus {
  /// Chưa fetch lần nào (cũng là trạng thái sau [ResetFamily]).
  initial,
  /// Đang tải danh sách nhóm hoặc chi tiết một nhóm.
  loading,
  /// Đã có danh sách nhóm. Lưu ý: đồng thời xoá `currentGroupId`/`groupDetails`.
  loaded,
  /// Đang tải bản xem trước nhóm cho một lời mời đến.
  invitationPreviewLoading,
  /// Đã có bản xem trước nhóm trong `invitationPreviewDetails`.
  invitationPreviewLoaded,
  /// Thao tác gần nhất thất bại; thông điệp nằm ở `errorMessage`.
  error,
  /// Đang gửi yêu cầu tạo nhóm (bước 1 hoặc tạo một lần).
  creatingGroup,
  /// Tạo nhóm một lần thành công; tên nhóm nằm ở `createdGroupName`.
  groupCreated,
  /// Đã có chi tiết nhóm trong `groupDetails` (khớp với `currentGroupId`).
  groupDetailsLoaded,
  /// Gửi lời mời thành công; bloc tự tải lại chi tiết nhóm + lời mời đã gửi.
  memberInvited,
  /// Chủ nhóm đã loại một thành viên; bloc tự tải lại chi tiết nhóm + danh sách nhóm.
  memberRemoved,
  /// Đã lưu giới hạn chia sẻ riêng cho một thành viên; bloc tự tải lại chi tiết nhóm.
  memberPermissionsUpdated,
  /// Đã chuyển quyền chủ nhóm; UI thường hỏi tiếp "có rời nhóm không".
  ownershipTransferred,
  /// Đã rời hoặc xoá nhóm; nhóm đó được thêm vào `hiddenGroupIds`.
  groupLeft,
  /// Đã tải xong lời mời đến hoặc lời mời đã gửi.
  invitationsLoaded,
  /// Đã chấp nhận lời mời -> chuyển sang chờ chủ nhóm duyệt, CHƯA phải thành viên.
  invitationAccepted,
  /// Đã từ chối lời mời đến.
  invitationDeclined,
  /// Đã lưu cài đặt chung của nhóm (cũng là bước 2 của luồng tạo nhóm).
  groupUpdated,
  /// Chủ nhóm đã duyệt một yêu cầu tham gia. [BE-REQ-01]
  joinRequestApproved,
  /// Chủ nhóm đã từ chối một yêu cầu tham gia. [BE-REQ-02]
  joinRequestRejected,
  /// Người dùng đã đổi bộ chỉ số mình chia sẻ với cả nhóm.
  mySharingUpdated,
  /// Bước 1 tạo nhóm xong (POST /groups); `createdGroupId` sẵn sàng cho bước 2.
  groupNameCreated,
}

/// Sentinel phân biệt "không truyền tham số" với "truyền null" trong [FamilyState.copyWith],
/// nhờ đó có thể chủ động xoá một field nullable (ví dụ `groupDetails: null`).
const _familyStateUnset = Object();

/// Toàn bộ dữ liệu miền nhóm gia đình mà UI đọc.
///
/// Ba nhóm dữ liệu sống song song và không đè lên nhau:
/// danh sách nhóm (`summary`), nhóm đang mở (`currentGroupId` + `groupDetails`),
/// và bản xem trước lời mời (`invitationPreviewGroupId` + `invitationPreviewDetails`).
class FamilyState extends Equatable {
  final FamilyStatus status;
  /// Danh sách nhóm + số liệu tổng hợp, đã lọc bỏ `hiddenGroupIds`.
  final FamilyGroupSummary summary;
  final String? errorMessage;
  /// True khi lỗi 401 (phiên hết hạn) → nút "Thử lại" chuyển sang đăng nhập.
  final bool isSessionExpired;
  /// Tên nhóm vừa tạo bằng luồng tạo một lần ([CreateGroup]).
  final String? createdGroupName;
  /// ID nhóm vừa tạo (bước 1 của 2-step create flow). Null nếu chưa tạo.
  final String? createdGroupId;
  /// Chi tiết của nhóm `currentGroupId`. Null khi chưa tải xong hoặc vừa bị [FetchFamilyGroups] xoá.
  final GroupDetails? groupDetails;
  /// Nhóm đang mở ở màn chi tiết. Listener phải so với id của mình trước khi phản ứng.
  final String? currentGroupId;
  /// Lời mời người khác gửi cho mình, đang chờ mình phản hồi.
  final List<IncomingInvitation> incomingInvitations;
  /// Lời mời mình đã gửi đi, kèm trạng thái pending / pendingOwnerApproval / accepted...
  final List<OutgoingInvitation> outgoingInvitations;
  /// Owner only: thành viên đang chờ chủ nhóm duyệt (từ GET /groups/:id/pending-approvals).
  final List<OutgoingInvitation> pendingApprovals;
  /// Chi tiết nhóm dùng cho màn xem trước lời mời — tách khỏi `groupDetails` để không đè lên nhau.
  final GroupDetails? invitationPreviewDetails;
  /// Nhóm mà `invitationPreviewDetails` đang mô tả.
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


