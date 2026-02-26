import 'package:fe/presentation/family/bloc/family_bloc.dart';

/// Helper class for FamilyState logic
/// Reduces complex if-else conditions
class FamilyStateHelper {
  /// Checks if state should show loading indicator
  static bool shouldShowLoading(FamilyState state) {
    return state.status == FamilyStatus.initial;
  }

  /// Checks if state should show error screen
  static bool shouldShowErrorScreen(FamilyState state) {
    return state.status == FamilyStatus.error &&
        state.summary.groups.isEmpty &&
        state.incomingInvitations.isEmpty &&
        state.outgoingInvitations.isEmpty;
  }

  /// Checks if state should show content (has data or in valid states)
  static bool shouldShowContent(FamilyState state) {
    // Has data
    if (state.summary.groups.isNotEmpty ||
        state.incomingInvitations.isNotEmpty ||
        state.outgoingInvitations.isNotEmpty) {
      return true;
    }

    // Valid content states
    final contentStates = {
      FamilyStatus.loaded,
      FamilyStatus.creatingGroup,
      FamilyStatus.groupCreated,
      FamilyStatus.groupDetailsLoaded,
      FamilyStatus.memberInvited,
      FamilyStatus.memberRemoved,
      FamilyStatus.groupUpdated,
      FamilyStatus.ownershipTransferred,
      FamilyStatus.groupLeft,
      FamilyStatus.invitationsLoaded,
      FamilyStatus.invitationAccepted,
      FamilyStatus.invitationDeclined,
      FamilyStatus.loading,
    };

    return contentStates.contains(state.status);
  }

  /// Checks if state indicates a successful operation
  static bool isSuccessState(FamilyStatus status) {
    final successStates = {
      FamilyStatus.groupCreated,
      FamilyStatus.groupUpdated,
      FamilyStatus.memberInvited,
      FamilyStatus.memberRemoved,
      FamilyStatus.ownershipTransferred,
      FamilyStatus.invitationAccepted,
      FamilyStatus.invitationDeclined,
    };
    return successStates.contains(status);
  }

  /// Checks if state requires data refresh
  static bool requiresRefresh(FamilyStatus status) {
    final refreshStates = {
      FamilyStatus.groupCreated,
      FamilyStatus.groupUpdated,
      FamilyStatus.memberInvited,
      FamilyStatus.memberRemoved,
      FamilyStatus.ownershipTransferred,
      FamilyStatus.groupLeft,
      FamilyStatus.invitationAccepted,
      FamilyStatus.invitationDeclined,
    };
    return refreshStates.contains(status);
  }
}

