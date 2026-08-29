import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_group_summary.dart';
import 'package:fe/data/models/group/group_details.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';
import 'package:fe/data/repositories/family_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'family_event.dart';
part 'family_state.dart';

/// Bloc quản lý toàn bộ miền "nhóm gia đình": danh sách nhóm, chi tiết nhóm,
/// lời mời (đi/đến), hàng chờ duyệt và các quyền chia sẻ chỉ số.
///
/// ## Mô hình nghiệp vụ
/// - Mỗi nhóm có đúng một **owner** (`group.ownerId`); còn lại là **member**.
/// - Luồng tham gia gồm 2 chặng:
///   `owner mời (pending)` → `invitee chấp nhận (pendingOwnerApproval)` →
///   `owner duyệt (accepted)`. Chỉ sau chặng cuối invitee mới thực sự là thành viên.
/// - Quyền chia sẻ có 2 tầng: quyền chung của nhóm (`group.sharedMetrics`,
///   `medicationSharingAllowed`) và quyền riêng từng cặp người dùng
///   (`UpdateMemberPermissions`) — tầng riêng chỉ được **thu hẹp** trong phạm vi tầng chung.
///
/// ## Máy trạng thái (event → status, kèm event tự phát sinh)
/// | Event | Status phát ra | Reload kèm theo |
/// |---|---|---|
/// | `FetchFamilyGroups` | `loading` → `loaded` \| `error` | tự bắn `FetchOutgoingInvitations` + `FetchIncomingInvitations` |
/// | `CreateGroupName` (bước 1) | `creatingGroup` → `groupNameCreated` \| `error` | — (UI chuyển sang bước 2 nhờ `createdGroupId`) |
/// | `CreateGroup` (tạo 1 lần) | `creatingGroup` → `groupCreated` \| `error` | — |
/// | `UpdateGroup` (bước 2 / sửa nhóm) | `groupUpdated` \| `error` | `FetchFamilyGroups`, thêm `FetchGroupDetails` nếu đang mở đúng nhóm đó |
/// | `DeleteGroup` | `groupLeft` \| `error` | `FetchOutgoingInvitations` |
/// | `LeaveGroup` | `groupLeft` \| `error` | — |
/// | `FetchGroupDetails` | `loading` → `groupDetailsLoaded` \| `error` | — |
/// | `InviteMember` | `memberInvited` \| `error` | `FetchGroupDetails` + `FetchOutgoingInvitations` |
/// | `TransferOwnership` | `ownershipTransferred` \| `error` | `FetchGroupDetails` nếu đang mở chi tiết nhóm |
/// | `FetchIncomingInvitations` / `FetchOutgoingInvitations` | `invitationsLoaded` | — |
/// | `FetchInvitationPreview` | `invitationPreviewLoading` → `invitationPreviewLoaded` \| `error` | — |
/// | `AcceptInvitation` | `invitationAccepted` \| `error` | `FetchIncomingInvitations` |
/// | `DeclineInvitation` | `invitationDeclined` \| `error` | `FetchIncomingInvitations` |
/// | `RemoveMember` | `memberRemoved` \| `error` | `FetchGroupDetails` + `FetchFamilyGroups` |
/// | `FetchPendingApprovals` | *(không đổi status)* | — |
/// | `ApproveJoinRequest` | `joinRequestApproved` \| `error` | `FetchPendingApprovals` + `FetchGroupDetails` |
/// | `RejectJoinRequest` | `joinRequestRejected` \| `error` | `FetchPendingApprovals` |
/// | `UpdateMySharing` | `mySharingUpdated` \| `error` | `FetchGroupDetails` |
/// | `UpdateMemberPermissions` | `memberPermissionsUpdated` \| `error` | `FetchGroupDetails` |
/// | `ResetFamily` | về `FamilyState.initial()` | — |
///
/// ## Cạm bẫy cần nhớ
/// - `status` là **một biến dùng chung cho cả màn hình**. Listener của một nhóm
///   cụ thể phải tự đối chiếu `state.currentGroupId` (hoặc `invitationPreviewGroupId`)
///   trước khi phản ứng, nếu không sẽ ăn nhầm sự kiện của nhóm khác.
/// - `FetchFamilyGroups` **xoá** `currentGroupId` và `groupDetails`. Không bao giờ
///   bắn nó ngay sau một thao tác trong màn chi tiết nhóm — `GroupDetailsView` sẽ
///   thấy `currentGroupId == null`, tự fetch lại và rơi vào vòng lặp loading
///   (đây là lý do `_onInviteMember` cố tình không gọi nó).
/// - `AcceptInvitation` **không** cập nhật lạc quan `summary`/`memberCount`: người
///   dùng lúc đó mới ở trạng thái chờ owner duyệt, chưa phải thành viên nhóm.
/// - `hiddenGroupIds` là bộ lọc chỉ tồn tại phía FE, dùng để ẩn nhóm vừa rời/xoá
///   khỏi kết quả của những request đang bay dở và trả về dữ liệu cũ.
/// - Lỗi 401 ở `FetchFamilyGroups`, `FetchGroupDetails`, `FetchInvitationPreview`
///   được thử lại **đúng một lần** (cờ `isRetryAfter401`) để chờ interceptor làm
///   mới token; lần hai mới bật `isSessionExpired` cho UI mời đăng nhập lại.
class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository _familyRepository;

  FamilyBloc({required FamilyRepository familyRepository})
    : _familyRepository = familyRepository,
      super(FamilyState.initial()) {
    on<FetchFamilyGroups>(_onFetchFamilyGroups);
    on<CreateGroupName>(_onCreateGroupName);
    on<CreateGroup>(_onCreateGroup);
    on<UpdateGroup>(_onUpdateGroup);
    on<DeleteGroup>(_onDeleteGroup);
    on<LeaveGroup>(_onLeaveGroup);
    on<FetchGroupDetails>(_onFetchGroupDetails);
    on<InviteMember>(_onInviteMember);
    on<TransferOwnership>(_onTransferOwnership);
    on<FetchIncomingInvitations>(_onFetchIncomingInvitations);
    on<FetchOutgoingInvitations>(_onFetchOutgoingInvitations);
    on<FetchInvitationPreview>(_onFetchInvitationPreview);
    on<AcceptInvitation>(_onAcceptInvitation);
    on<DeclineInvitation>(_onDeclineInvitation);
    on<RemoveMember>(_onRemoveMember);
    on<UpdateMySharing>(_onUpdateMySharing);
    on<UpdateMemberPermissions>(_onUpdateMemberPermissions);
    on<FetchPendingApprovals>(_onFetchPendingApprovals);
    on<ApproveJoinRequest>(_onApproveJoinRequest);
    on<RejectJoinRequest>(_onRejectJoinRequest);
    on<ResetFamily>(_onResetFamily);
  }

  /// Cho phép dialog gọi thẳng repository với những truy vấn một lần, không đáng
  /// thêm event/state riêng (ví dụ `getMySpecificMetricsForMember` để prefill form).
  FamilyRepository get repository => _familyRepository;

  void _onResetFamily(ResetFamily event, Emitter<FamilyState> emit) {
    emit(FamilyState.initial());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Lọc bỏ những nhóm người dùng vừa rời/xoá khỏi summary vừa nhận từ server.
  /// BE có thể còn trả về chúng trong vài giây (cache/replica trễ), nếu không lọc
  /// thì nhóm đã rời sẽ "hiện lại" ngay sau khi biến mất.
  FamilyGroupSummary _applyHiddenGroups(FamilyGroupSummary summary) {
    if (state.hiddenGroupIds.isEmpty) return summary;
    final filtered = summary.groups
        .where((g) => !state.hiddenGroupIds.contains(g.id))
        .toList();
    return summary.copyWith(groups: filtered, groupsJoined: filtered.length);
  }

  /// Trả summary đã bỏ nhóm [groupId] khỏi danh sách.
  FamilyGroupSummary _summaryWithoutGroup(String groupId) {
    final updatedGroups = state.summary.groups
        .where((g) => g.id != groupId)
        .toList();
    return state.summary.copyWith(
      groups: updatedGroups,
      groupsJoined: updatedGroups.length,
    );
  }

  /// Thêm [groupId] vào danh sách ẩn cục bộ (xem [_applyHiddenGroups]).
  Set<String> _hideGroupId(String groupId) {
    final next = <String>{...state.hiddenGroupIds};
    next.add(groupId);
    return next;
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onFetchFamilyGroups(
    FetchFamilyGroups event,
    Emitter<FamilyState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FamilyStatus.loading,
        errorMessage: null,
        isSessionExpired: false,
      ),
    );
    try {
      final summary = await _familyRepository.getFamilyGroups();
      emit(
        state.copyWith(
          status: FamilyStatus.loaded,
          summary: _applyHiddenGroups(summary),
          errorMessage: null,
          isSessionExpired: false,
          currentGroupId: null,
          groupDetails: null,
        ),
      );
      if (!isClosed) {
        add(const FetchOutgoingInvitations());
        add(const FetchIncomingInvitations());
      }
    } catch (e) {
      final isUnauthorized = e is UnauthorizedException;
      if (isUnauthorized && !event.isRetryAfter401) {
        emit(state.copyWith(status: FamilyStatus.loading, errorMessage: null));
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!isClosed) add(const FetchFamilyGroups(isRetryAfter401: true));
        });
        return;
      }
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
          isSessionExpired: isUnauthorized,
        ),
      );
    }
  }

  Future<void> _onCreateGroupName(
    CreateGroupName event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(status: FamilyStatus.creatingGroup, errorMessage: null));
    try {
      // Chỉ POST /groups với tên. Truyền sharedMetrics rỗng để service bỏ qua
      // bước PUT permissions — bước 2 của luồng tạo nhóm sẽ gửi qua UpdateGroup.
      final newGroup = await _familyRepository.createGroup(
        name: event.name,
        sharedMetrics: const [],
      );
      final updatedGroups = [newGroup, ...state.summary.groups];
      emit(state.copyWith(
        status: FamilyStatus.groupNameCreated,
        summary: state.summary.copyWith(
          groups: updatedGroups,
          groupsJoined: updatedGroups.length,
        ),
        createdGroupId: newGroup.id,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: UserFacingError.message(e),
      ));
    }
  }

  Future<void> _onCreateGroup(
    CreateGroup event,
    Emitter<FamilyState> emit,
  ) async {
    emit(
      state.copyWith(status: FamilyStatus.creatingGroup, errorMessage: null),
    );
    try {
      final newGroup = await _familyRepository.createGroup(
        name: event.name,
        sharedMetrics: event.sharedMetrics,
        enableMedicationReminderShare: event.enableMedicationReminderShare,
      );
      final updatedGroups = [newGroup, ...state.summary.groups];
      emit(
        state.copyWith(
          status: FamilyStatus.groupCreated,
          summary: state.summary.copyWith(
            groups: updatedGroups,
            groupsJoined: updatedGroups.length,
          ),
          createdGroupName: event.name,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onUpdateGroup(
    UpdateGroup event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.updateGroup(
        groupId: event.groupId,
        name: event.name,
        sharedMetrics: event.sharedMetrics,
        enableMedicationReminderShare: event.enableMedicationReminderShare,
      );
      final currentGroupDetails = state.groupDetails;
      final currentGroupId = state.currentGroupId;

      emit(
        state.copyWith(status: FamilyStatus.groupUpdated, errorMessage: null),
      );
      add(FetchFamilyGroups());
      if (currentGroupDetails != null && currentGroupId == event.groupId) {
        add(FetchGroupDetails(groupId: event.groupId));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onDeleteGroup(
    DeleteGroup event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.deleteGroup(groupId: event.groupId);
      emit(
        state.copyWith(
          status: FamilyStatus.groupLeft,
          summary: _summaryWithoutGroup(event.groupId),
          hiddenGroupIds: _hideGroupId(event.groupId),
          errorMessage: null,
        ),
      );
      add(const FetchOutgoingInvitations());
    } catch (e) {
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onLeaveGroup(
    LeaveGroup event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.leaveGroup(groupId: event.groupId);
      emit(
        state.copyWith(
          status: FamilyStatus.groupLeft,
          summary: _summaryWithoutGroup(event.groupId),
          groupDetails: null,
          currentGroupId: null,
          hiddenGroupIds: _hideGroupId(event.groupId),
          errorMessage: null,
        ),
      );
    } catch (e) {
      // 404 "member not found" → user đã không còn trong nhóm, coi như đã rời thành công
      if (e is NotFoundException) {
        emit(
          state.copyWith(
            status: FamilyStatus.groupLeft,
            summary: _summaryWithoutGroup(event.groupId),
            groupDetails: null,
            currentGroupId: null,
            hiddenGroupIds: _hideGroupId(event.groupId),
            errorMessage: null,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onFetchGroupDetails(
    FetchGroupDetails event,
    Emitter<FamilyState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FamilyStatus.loading,
        currentGroupId: event.groupId,
        groupDetails: null,
        errorMessage: null,
        isSessionExpired: false,
      ),
    );
    try {
      FamilyGroup? cachedGroup;
      for (final g in state.summary.groups) {
        if (g.id == event.groupId) {
          cachedGroup = g;
          break;
        }
      }
      final details = await _familyRepository.getGroupDetails(
        groupId: event.groupId,
        cachedGroup: cachedGroup,
      );

      // Đồng bộ lại memberCount trong summary theo dữ liệu chi tiết nhóm (members.length)
      // để danh sách nhóm và màn chi tiết luôn khớp nhau.
      final groups = [...state.summary.groups];
      final index = groups.indexWhere((g) => g.id == event.groupId);
      var updatedSummary = state.summary;
      if (index != -1) {
        final group = groups[index];
        groups[index] = group.copyWith(memberCount: details.members.length);
        updatedSummary = state.summary.copyWith(
          groups: groups,
          groupsJoined: groups.length,
        );
      }

      emit(
        state.copyWith(
          status: FamilyStatus.groupDetailsLoaded,
          groupDetails: details,
          summary: updatedSummary,
          errorMessage: null,
        ),
      );
    } catch (e) {
      final isUnauthorized = e is UnauthorizedException;
      if (isUnauthorized && !event.isRetryAfter401) {
        emit(state.copyWith(status: FamilyStatus.loading, errorMessage: null));
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!isClosed) {
            add(
              FetchGroupDetails(groupId: event.groupId, isRetryAfter401: true),
            );
          }
        });
        return;
      }
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
          isSessionExpired: isUnauthorized,
        ),
      );
    }
  }

  Future<void> _onInviteMember(
    InviteMember event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.inviteMember(
        groupId: event.groupId,
        email: event.email,
        name: event.name,
        relationship: event.relationship,
        age: event.age,
        sharedMetrics: event.sharedMetrics,
        userId: event.userId,
      );
      emit(
        state.copyWith(status: FamilyStatus.memberInvited, errorMessage: null),
      );
      add(FetchGroupDetails(groupId: event.groupId));
      // Không dispatch FetchFamilyGroups ở đây: nó set currentGroupId=null
      // khiến GroupDetailsView reset và trig lại FetchGroupDetails → loop loading.
      // FetchGroupDetails đã cập nhật memberCount trong summary rồi.
      add(const FetchOutgoingInvitations());
    } catch (e) {
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.inviteMember(e),
        ),
      );
    }
  }

  Future<void> _onTransferOwnership(
    TransferOwnership event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.transferOwnership(
        groupId: event.groupId,
        newOwnerId: event.newOwnerId,
      );
      final currentGroupDetails = state.groupDetails;

      emit(
        state.copyWith(
          status: FamilyStatus.ownershipTransferred,
          errorMessage: null,
        ),
      );
      if (currentGroupDetails != null) {
        add(FetchGroupDetails(groupId: event.groupId));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onFetchIncomingInvitations(
    FetchIncomingInvitations event,
    Emitter<FamilyState> emit,
  ) async {
    if (state.incomingInvitations.isEmpty &&
        state.status == FamilyStatus.initial) {
      emit(state.copyWith(status: FamilyStatus.loading));
    }
    try {
      final invitations = await _familyRepository.getIncomingInvitations();
      emit(
        state.copyWith(
          status: FamilyStatus.invitationsLoaded,
          incomingInvitations: invitations,
        ),
      );
    } catch (e) {
      if (state.incomingInvitations.isEmpty) {
        emit(
          state.copyWith(
            status: FamilyStatus.error,
            errorMessage: UserFacingError.message(e),
          ),
        );
      }
    }
  }

  Future<void> _onFetchOutgoingInvitations(
    FetchOutgoingInvitations event,
    Emitter<FamilyState> emit,
  ) async {
    if (state.outgoingInvitations.isEmpty &&
        state.status == FamilyStatus.initial) {
      emit(state.copyWith(status: FamilyStatus.loading));
    }
    try {
      final invitations = await _familyRepository.getOutgoingInvitations();
      emit(
        state.copyWith(
          status: FamilyStatus.invitationsLoaded,
          outgoingInvitations: invitations,
        ),
      );
    } catch (e) {
      if (state.outgoingInvitations.isEmpty) {
        emit(
          state.copyWith(
            status: FamilyStatus.error,
            errorMessage: UserFacingError.message(e),
          ),
        );
      }
    }
  }

  Future<void> _onFetchInvitationPreview(
    FetchInvitationPreview event,
    Emitter<FamilyState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FamilyStatus.invitationPreviewLoading,
        invitationPreviewGroupId: event.groupId,
        invitationPreviewDetails: null,
        errorMessage: null,
        isSessionExpired: false,
      ),
    );
    try {
      FamilyGroup? cachedGroup;
      for (final g in state.summary.groups) {
        if (g.id == event.groupId) {
          cachedGroup = g;
          break;
        }
      }
      if (cachedGroup == null) {
        for (final invitation in state.incomingInvitations) {
          if (invitation.group?.id == event.groupId) {
            cachedGroup = invitation.group;
            break;
          }
        }
      }

      final details = await _familyRepository.getGroupDetails(
        groupId: event.groupId,
        cachedGroup: cachedGroup,
      );
      emit(
        state.copyWith(
          status: FamilyStatus.invitationPreviewLoaded,
          invitationPreviewGroupId: event.groupId,
          invitationPreviewDetails: details,
          errorMessage: null,
        ),
      );
    } catch (e) {
      final isUnauthorized = e is UnauthorizedException;
      if (isUnauthorized && !event.isRetryAfter401) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!isClosed) {
            add(
              FetchInvitationPreview(
                groupId: event.groupId,
                isRetryAfter401: true,
              ),
            );
          }
        });
        return;
      }
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
          isSessionExpired: isUnauthorized,
        ),
      );
    }
  }

  Future<void> _onAcceptInvitation(
    AcceptInvitation event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.acceptInvitation(
        groupId: event.groupId,
        sharedMetrics: event.sharedMetrics,
      );

      // [BE-REQ-03] Sau khi BE triển khai pending_owner_approval:
      // Invitee chấp nhận → trạng thái chuyển sang pending_owner_approval,
      // user CHƯA join nhóm. Chủ nhóm cần duyệt thêm một bước.
      //
      // FE không cập nhật optimistic memberCount hay FetchFamilyGroups
      // vì user chưa thực sự là thành viên nhóm.
      emit(
        state.copyWith(
          status: FamilyStatus.invitationAccepted,
          errorMessage: null,
        ),
      );
      // Xoá invitation khỏi danh sách incoming (invitee đã phản hồi).
      add(const FetchIncomingInvitations());
    } catch (e) {
      if (e is NotFoundException) {
        emit(
          state.copyWith(
            status: FamilyStatus.error,
            errorMessage:
                'Nhóm không còn tồn tại hoặc đã bị xóa. Lời mời đã được loại bỏ.',
          ),
        );
        add(const FetchIncomingInvitations());
        return;
      }
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onFetchPendingApprovals(
    FetchPendingApprovals event,
    Emitter<FamilyState> emit,
  ) async {
    try {
      final approvals = await _familyRepository.getPendingApprovals(
        groupId: event.groupId,
      );
      emit(state.copyWith(pendingApprovals: approvals));
    } catch (_) {
      // Non-fatal: pending approvals không hiển thị được thì để danh sách rỗng.
      emit(state.copyWith(pendingApprovals: const []));
    }
  }

  Future<void> _onApproveJoinRequest(
    ApproveJoinRequest event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.approveJoinRequest(
        groupId: event.groupId,
        memberId: event.memberId,
      );
      emit(state.copyWith(status: FamilyStatus.joinRequestApproved));
      // Refresh: cập nhật danh sách chờ duyệt + members trong nhóm.
      add(FetchPendingApprovals(groupId: event.groupId));
      add(FetchGroupDetails(groupId: event.groupId));
    } catch (e) {
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onRejectJoinRequest(
    RejectJoinRequest event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.rejectJoinRequest(
        groupId: event.groupId,
        memberId: event.memberId,
      );
      emit(state.copyWith(status: FamilyStatus.joinRequestRejected));
      // Refresh danh sách chờ duyệt.
      add(FetchPendingApprovals(groupId: event.groupId));
    } catch (e) {
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onDeclineInvitation(
    DeclineInvitation event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.declineInvitation(groupId: event.groupId);
      emit(
        state.copyWith(
          status: FamilyStatus.invitationDeclined,
          errorMessage: null,
        ),
      );
      add(const FetchIncomingInvitations());
    } catch (e) {
      if (e is NotFoundException) {
        emit(
          state.copyWith(
            status: FamilyStatus.error,
            errorMessage:
                'Nhóm không còn tồn tại hoặc đã bị xóa. Lời mời đã được loại bỏ.',
          ),
        );
        add(const FetchIncomingInvitations());
        return;
      }
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onRemoveMember(
    RemoveMember event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.removeMember(
        groupId: event.groupId,
        memberId: event.memberId,
      );
      emit(
        state.copyWith(status: FamilyStatus.memberRemoved, errorMessage: null),
      );
      add(FetchGroupDetails(groupId: event.groupId));
      add(const FetchFamilyGroups());
    } catch (e) {
      emit(
        state.copyWith(
          status: FamilyStatus.error,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onUpdateMySharing(
    UpdateMySharing event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.updateMySharing(
        groupId: event.groupId,
        sharedMetrics: event.sharedMetrics,
      );
      emit(state.copyWith(
        status: FamilyStatus.mySharingUpdated,
        errorMessage: null,
      ));
      add(FetchGroupDetails(groupId: event.groupId));
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: UserFacingError.message(e),
      ));
    }
  }

  Future<void> _onUpdateMemberPermissions(
    UpdateMemberPermissions event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.updateMemberPermissions(
        groupId: event.groupId,
        memberId: event.memberId,
        sharedMetrics: event.sharedMetrics,
        allowMedicationReminderShare: event.allowMedicationReminderShare,
      );
      emit(state.copyWith(
        status: FamilyStatus.memberPermissionsUpdated,
        errorMessage: null,
      ));
      add(FetchGroupDetails(groupId: event.groupId));
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: UserFacingError.message(e),
      ));
    }
  }
}
