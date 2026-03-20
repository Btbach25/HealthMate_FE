import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/error_message_parser.dart';
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

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository _familyRepository;

  FamilyBloc({required FamilyRepository familyRepository})
      : _familyRepository = familyRepository,
        super(FamilyState.initial()) {
    on<FetchFamilyGroups>(_onFetchFamilyGroups);
    on<CreateGroup>(_onCreateGroup);
    on<UpdateGroup>(_onUpdateGroup);
    on<DeleteGroup>(_onDeleteGroup);
    on<LeaveGroup>(_onLeaveGroup);
    on<FetchGroupDetails>(_onFetchGroupDetails);
    on<InviteMember>(_onInviteMember);
    on<TransferOwnership>(_onTransferOwnership);
    on<FetchIncomingInvitations>(_onFetchIncomingInvitations);
    on<FetchOutgoingInvitations>(_onFetchOutgoingInvitations);
    on<AcceptInvitation>(_onAcceptInvitation);
    on<DeclineInvitation>(_onDeclineInvitation);
    on<RemoveMember>(_onRemoveMember);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  FamilyGroupSummary _applyHiddenGroups(FamilyGroupSummary summary) {
    if (state.hiddenGroupIds.isEmpty) return summary;
    final filtered =
        summary.groups.where((g) => !state.hiddenGroupIds.contains(g.id)).toList();
    return summary.copyWith(groups: filtered, groupsJoined: filtered.length);
  }

  /// Trả summary đã bỏ nhóm [groupId] khỏi danh sách.
  FamilyGroupSummary _summaryWithoutGroup(String groupId) {
    final updatedGroups = state.summary.groups.where((g) => g.id != groupId).toList();
    return state.summary.copyWith(groups: updatedGroups, groupsJoined: updatedGroups.length);
  }

  Set<String> _hideGroupId(String groupId) {
    final next = <String>{...state.hiddenGroupIds};
    next.add(groupId);
    return next;
  }

  Set<String> _unhideGroupId(String groupId) {
    if (state.hiddenGroupIds.isEmpty) return state.hiddenGroupIds;
    final next = <String>{...state.hiddenGroupIds};
    next.remove(groupId);
    return next;
  }

  /// Parse lỗi thành message tiếng Việt, dùng [ErrorMessageParser] + bổ sung
  /// các case đặc thù cho groups (CORS, UUID, ...).
  String _parseError(dynamic error) {
    final errorMessage = error.toString();
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('cors') ||
        (lowerError.contains('redirect') && lowerError.contains('preflight')) ||
        lowerError.contains('err_failed') ||
        (lowerError.contains('blocked') && lowerError.contains('policy'))) {
      return 'Không tải được danh sách nhóm (lỗi CORS). '
          'Khi chạy web, cần cấu hình api-gateway: OPTIONS /groups trả 200, không redirect.';
    }

    if (lowerError.contains('invalid uuid format')) {
      return 'Lỗi format UUID. Có thể do đăng nhập Google (JWT dùng ID không phải UUID).';
    }

    return ErrorMessageParser.parse(errorMessage);
  }

  /// Parse lỗi riêng cho invite member (nhiều case chi tiết hơn).
  String _parseInviteMemberError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('invalid request')) {
      return 'Yêu cầu không hợp lệ (400). Kiểm tra: (1) Email đúng định dạng, '
          '(2) Tài khoản đã đăng ký với email này.';
    }
    if (lowerError.contains('invitation is still pending') ||
        lowerError.contains('still pending')) {
      return 'Lời mời đang chờ người này phản hồi. Không thể gửi thêm.';
    }
    if (lowerError.contains('already a member')) {
      return 'Người này đã là thành viên của nhóm.';
    }

    return _parseError(errorMessage);
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onFetchFamilyGroups(
    FetchFamilyGroups event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(
      status: FamilyStatus.loading,
      errorMessage: null,
      isSessionExpired: false,
    ));
    try {
      final summary = await _familyRepository.getFamilyGroups();
      emit(state.copyWith(
        status: FamilyStatus.loaded,
        summary: _applyHiddenGroups(summary),
        errorMessage: null,
        isSessionExpired: false,
        currentGroupId: null,
        groupDetails: null,
      ));
    } catch (e) {
      final isUnauthorized = e is UnauthorizedException;
      if (isUnauthorized && !event.isRetryAfter401) {
        emit(state.copyWith(status: FamilyStatus.loading, errorMessage: null));
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!isClosed) add(const FetchFamilyGroups(isRetryAfter401: true));
        });
        return;
      }
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e),
        isSessionExpired: isUnauthorized,
      ));
    }
  }

  Future<void> _onCreateGroup(
    CreateGroup event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(status: FamilyStatus.creatingGroup, errorMessage: null));
    try {
      final newGroup = await _familyRepository.createGroup(
        name: event.name,
        sharedMetrics: event.sharedMetrics,
      );
      final updatedGroups = [newGroup, ...state.summary.groups];
      emit(state.copyWith(
        status: FamilyStatus.groupCreated,
        summary: state.summary.copyWith(
          groups: updatedGroups,
          groupsJoined: updatedGroups.length,
        ),
        createdGroupName: event.name,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e),
      ));
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
      );
      final currentGroupDetails = state.groupDetails;
      final currentGroupId = state.currentGroupId;

      emit(state.copyWith(
        status: FamilyStatus.groupUpdated,
        errorMessage: null,
      ));
      add(FetchFamilyGroups());
      if (currentGroupDetails != null && currentGroupId == event.groupId) {
        add(FetchGroupDetails(groupId: event.groupId));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e),
      ));
    }
  }

  Future<void> _onDeleteGroup(
    DeleteGroup event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.deleteGroup(groupId: event.groupId);
      emit(state.copyWith(
        status: FamilyStatus.groupLeft,
        summary: _summaryWithoutGroup(event.groupId),
        hiddenGroupIds: _hideGroupId(event.groupId),
        errorMessage: null,
      ));
      add(const FetchOutgoingInvitations());
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e),
      ));
    }
  }

  Future<void> _onLeaveGroup(
    LeaveGroup event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.leaveGroup(groupId: event.groupId);
      emit(state.copyWith(
        status: FamilyStatus.groupLeft,
        summary: _summaryWithoutGroup(event.groupId),
        groupDetails: null,
        currentGroupId: null,
        hiddenGroupIds: _hideGroupId(event.groupId),
        errorMessage: null,
      ));
    } catch (e) {
      // 404 "member not found" → user đã không còn trong nhóm, coi như đã rời thành công
      if (e is NotFoundException) {
        emit(state.copyWith(
          status: FamilyStatus.groupLeft,
          summary: _summaryWithoutGroup(event.groupId),
          groupDetails: null,
          currentGroupId: null,
          hiddenGroupIds: _hideGroupId(event.groupId),
          errorMessage: null,
        ));
        return;
      }
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e),
      ));
    }
  }

  Future<void> _onFetchGroupDetails(
    FetchGroupDetails event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(
      status: FamilyStatus.loading,
      currentGroupId: event.groupId,
      groupDetails: null,
      errorMessage: null,
      isSessionExpired: false,
    ));
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

      emit(state.copyWith(
        status: FamilyStatus.groupDetailsLoaded,
        groupDetails: details,
        summary: updatedSummary,
        errorMessage: null,
      ));
    } catch (e) {
      final isUnauthorized = e is UnauthorizedException;
      if (isUnauthorized && !event.isRetryAfter401) {
        emit(state.copyWith(status: FamilyStatus.loading, errorMessage: null));
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!isClosed) {
            add(FetchGroupDetails(
                groupId: event.groupId, isRetryAfter401: true));
          }
        });
        return;
      }
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e),
        isSessionExpired: isUnauthorized,
      ));
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
      emit(state.copyWith(
        status: FamilyStatus.memberInvited,
        errorMessage: null,
      ));
      add(FetchGroupDetails(groupId: event.groupId));
      add(const FetchFamilyGroups());
      add(const FetchOutgoingInvitations());
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseInviteMemberError(e.toString()),
      ));
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

      emit(state.copyWith(
        status: FamilyStatus.ownershipTransferred,
        errorMessage: null,
      ));
      if (currentGroupDetails != null) {
        add(FetchGroupDetails(groupId: event.groupId));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e),
      ));
    }
  }

  Future<void> _onFetchIncomingInvitations(
    FetchIncomingInvitations event,
    Emitter<FamilyState> emit,
  ) async {
    if (state.incomingInvitations.isEmpty) {
      emit(state.copyWith(status: FamilyStatus.loading));
    }
    try {
      final invitations = await _familyRepository.getIncomingInvitations();
      emit(state.copyWith(
        status: FamilyStatus.invitationsLoaded,
        incomingInvitations: invitations,
        summary: state.summary.copyWith(
          pendingInvitations: invitations.length,
        ),
      ));
    } catch (e) {
      if (state.incomingInvitations.isEmpty) {
        emit(state.copyWith(
          status: FamilyStatus.error,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  Future<void> _onFetchOutgoingInvitations(
    FetchOutgoingInvitations event,
    Emitter<FamilyState> emit,
  ) async {
    if (state.outgoingInvitations.isEmpty) {
      emit(state.copyWith(status: FamilyStatus.loading));
    }
    try {
      final invitations = await _familyRepository.getOutgoingInvitations();
      emit(state.copyWith(
        status: FamilyStatus.invitationsLoaded,
        outgoingInvitations: invitations,
      ));
    } catch (e) {
      if (state.outgoingInvitations.isEmpty) {
        emit(state.copyWith(
          status: FamilyStatus.error,
          errorMessage: e.toString(),
        ));
      }
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

      // Cập nhật optimistic số thành viên trong nhóm ngay lập tức,
      // dùng memberCount từ invitation (nếu có) + 1 cho người vừa tham gia.
      final groups = [...state.summary.groups];
      final index = groups.indexWhere((g) => g.id == event.groupId);
      var updatedSummary = state.summary;
      if (index != -1) {
        final group = groups[index];
        final baseCount = event.currentMemberCount ?? group.memberCount;
        final newCount = (baseCount > 0 ? baseCount + 1 : 1);
        groups[index] = group.copyWith(memberCount: newCount);
        updatedSummary = state.summary.copyWith(
          groups: groups,
          groupsJoined: groups.length,
        );
      }

      emit(state.copyWith(
        status: FamilyStatus.invitationAccepted,
        hiddenGroupIds: _unhideGroupId(event.groupId),
        summary: updatedSummary,
        errorMessage: null,
      ));
      add(const FetchIncomingInvitations());
      add(const FetchFamilyGroups());
    } catch (e) {
      if (e is NotFoundException) {
        emit(state.copyWith(
          status: FamilyStatus.error,
          errorMessage: 'Nhóm không còn tồn tại hoặc đã bị xóa. Lời mời đã được loại bỏ.',
        ));
        add(const FetchIncomingInvitations());
        return;
      }
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e),
      ));
    }
  }

  Future<void> _onDeclineInvitation(
    DeclineInvitation event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.declineInvitation(groupId: event.groupId);
      emit(state.copyWith(
        status: FamilyStatus.invitationDeclined,
        errorMessage: null,
      ));
      add(const FetchIncomingInvitations());
    } catch (e) {
      if (e is NotFoundException) {
        emit(state.copyWith(
          status: FamilyStatus.error,
          errorMessage: 'Nhóm không còn tồn tại hoặc đã bị xóa. Lời mời đã được loại bỏ.',
        ));
        add(const FetchIncomingInvitations());
        return;
      }
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e),
      ));
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
      emit(state.copyWith(
        status: FamilyStatus.memberRemoved,
        errorMessage: null,
      ));
      add(FetchGroupDetails(groupId: event.groupId));
      add(const FetchFamilyGroups());
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e),
      ));
    }
  }
}
