import 'package:equatable/equatable.dart';
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

  Future<void> _onFetchFamilyGroups(
    FetchFamilyGroups event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(status: FamilyStatus.loading, errorMessage: null));
    try {
      final summary = await _familyRepository.getFamilyGroups();
      emit(state.copyWith(
        status: FamilyStatus.loaded,
        summary: summary,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e.toString()),
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
        errorMessage: _parseError(e.toString()),
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
      // Store current values before emitting to avoid stale state
      final currentGroupDetails = state.groupDetails;
      final currentGroupId = state.currentGroupId;
      
      emit(state.copyWith(
        status: FamilyStatus.groupUpdated,
        errorMessage: null,
      ));
      // Refresh data
      add(FetchFamilyGroups());
      if (currentGroupDetails != null && currentGroupId == event.groupId) {
        add(FetchGroupDetails(groupId: event.groupId));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e.toString()),
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
      final updatedGroups = state.summary.groups
          .where((g) => g.id != event.groupId)
          .toList();
      emit(state.copyWith(
        status: FamilyStatus.loaded,
        summary: state.summary.copyWith(
          groups: updatedGroups,
          groupsJoined: updatedGroups.length,
        ),
        errorMessage: null,
      ));
      // Refresh outgoing invitations to remove deleted group's invitations
      add(const FetchOutgoingInvitations());
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e.toString()),
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
      final updatedGroups = state.summary.groups
          .where((g) => g.id != event.groupId)
          .toList();
      final updatedSummary = state.summary.copyWith(
        groups: updatedGroups,
        groupsJoined: updatedGroups.length,
      );
      // Single emit with loaded status and cleared group details
      emit(state.copyWith(
        status: FamilyStatus.loaded,
        summary: updatedSummary,
        groupDetails: null,
        currentGroupId: null,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e.toString()),
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
    ));
    try {
      final details = await _familyRepository.getGroupDetails(groupId: event.groupId);
      emit(state.copyWith(
        status: FamilyStatus.groupDetailsLoaded,
        groupDetails: details,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e.toString()),
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
      );
      emit(state.copyWith(
        status: FamilyStatus.memberInvited,
        errorMessage: null,
      ));
      // Refresh group details, groups list, and outgoing invitations
      add(FetchGroupDetails(groupId: event.groupId));
      add(const FetchFamilyGroups());
      add(const FetchOutgoingInvitations());
    } catch (e) {
      // Parse error message để hiển thị tiếng Việt
      final errorMsg = _parseInviteMemberError(e.toString());
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: errorMsg,
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
      // Store current groupDetails before emitting to avoid stale state
      final currentGroupDetails = state.groupDetails;
      
      emit(state.copyWith(
        status: FamilyStatus.ownershipTransferred,
        errorMessage: null,
      ));
      // Refresh data
      add(const FetchFamilyGroups());
      if (currentGroupDetails != null) {
        add(FetchGroupDetails(groupId: event.groupId));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e.toString()),
      ));
    }
  }

  Future<void> _onFetchIncomingInvitations(
    FetchIncomingInvitations event,
    Emitter<FamilyState> emit,
  ) async {
    // Don't set loading status if we already have data (for smooth tab switching)
    // Only set loading if this is the first time fetching
    if (state.incomingInvitations.isEmpty) {
      emit(state.copyWith(status: FamilyStatus.loading));
    }
    try {
      final invitations = await _familyRepository.getIncomingInvitations();
      emit(state.copyWith(
        status: FamilyStatus.invitationsLoaded,
        incomingInvitations: invitations,
      ));
    } catch (e) {
      // Only show error if we don't have any data
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
    // Don't set loading status if we already have data (for smooth tab switching)
    // Only set loading if this is the first time fetching
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
      // Only show error if we don't have any data
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
        invitationId: event.invitationId,
        sharedMetrics: event.sharedMetrics,
      );
      emit(state.copyWith(
        status: FamilyStatus.invitationAccepted,
        errorMessage: null,
      ));
      // Refresh invitations and groups
      add(const FetchIncomingInvitations());
      add(const FetchFamilyGroups());
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e.toString()),
      ));
    }
  }

  Future<void> _onDeclineInvitation(
    DeclineInvitation event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
    try {
      await _familyRepository.declineInvitation(invitationId: event.invitationId);
      emit(state.copyWith(
        status: FamilyStatus.invitationDeclined,
        errorMessage: null,
      ));
      // Refresh invitations
      add(const FetchIncomingInvitations());
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e.toString()),
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
      // Refresh group details and groups list
      add(FetchGroupDetails(groupId: event.groupId));
      add(const FetchFamilyGroups());
    } catch (e) {
      emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: _parseError(e.toString()),
      ));
    }
  }

  // Centralized error parsing method
  // This method handles both ApiException and regular exceptions
  String _parseError(dynamic error) {
    // If it's already an ApiException, use its message
    if (error is Exception) {
      final errorMessage = error.toString();
      final lowerError = errorMessage.toLowerCase();
      
      // Network errors
      if (lowerError.contains('network') || 
          lowerError.contains('connection') ||
          lowerError.contains('socket')) {
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.';
      }
      
      // Timeout errors
      if (lowerError.contains('timeout')) {
        return 'Yêu cầu quá thời gian chờ. Vui lòng thử lại.';
      }
      
      // Permission errors
      if (lowerError.contains('permission') || 
          lowerError.contains('unauthorized') ||
          lowerError.contains('forbidden')) {
        return 'Bạn không có quyền thực hiện thao tác này.';
      }
      
      // Not found errors
      if (lowerError.contains('not found') || 
          lowerError.contains('không tìm thấy')) {
        return 'Không tìm thấy dữ liệu. Vui lòng thử lại.';
      }
      
      // Validation errors
      if (lowerError.contains('invalid') || 
          lowerError.contains('không hợp lệ')) {
        return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
      }
      
      // Default fallback
      return errorMessage.contains('Exception:') 
          ? 'Có lỗi xảy ra. Vui lòng thử lại sau.'
          : errorMessage;
    }
    
    // For non-Exception types, convert to string
    final errorMessage = error.toString();
    return errorMessage.contains('Exception:') 
        ? 'Có lỗi xảy ra. Vui lòng thử lại sau.'
        : errorMessage;
  }

  // Helper method để parse error message cho invite member (specific parsing)
  String _parseInviteMemberError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();
    
    if (lowerError.contains('không tìm thấy nhóm') || 
        lowerError.contains('group not found')) {
      return 'Không tìm thấy nhóm. Vui lòng thử lại.';
    }
    if (lowerError.contains('email không hợp lệ') || 
        (lowerError.contains('email') && lowerError.contains('invalid'))) {
      return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
    }
    if (lowerError.contains('đã được mời') || 
        (lowerError.contains('email') && lowerError.contains('already'))) {
      return 'Email này đã được mời vào nhóm.';
    }
    
    // Fallback to general error parser
    return _parseError(errorMessage);
  }
}

