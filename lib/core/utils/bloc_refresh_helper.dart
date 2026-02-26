import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Helper class to manage BLoC state refresh logic
/// Reusable across different pages that need to refresh data based on state changes
class BlocRefreshHelper<B extends StateStreamable<S>, S> {
  final Set<dynamic> refreshTriggerStates;
  final void Function(BuildContext, B) onRefresh;
  final dynamic initialState;
  final dynamic Function(S)? statusExtractor;

  const BlocRefreshHelper({
    required this.refreshTriggerStates,
    required this.onRefresh,
    required this.initialState,
    this.statusExtractor,
  });

  /// Checks if the current state should trigger a refresh
  bool shouldRefresh(S currentState) {
    final status = statusExtractor?.call(currentState) ?? 
                   (currentState as dynamic).status;
    return refreshTriggerStates.contains(status);
  }

  /// Checks if the current state is the initial state
  bool isInitialState(S currentState) {
    final status = statusExtractor?.call(currentState) ?? 
                   (currentState as dynamic).status;
    return status == initialState;
  }

  /// Handles state change and triggers refresh if needed
  /// Returns true if refresh was triggered, false otherwise
  /// Note: Refresh is triggered when state matches trigger states, regardless of hasInitialized
  bool handleStateChange(BuildContext context, S state, bool hasInitialized) {
    // Only refresh if state matches trigger states
    // hasInitialized is only used to prevent multiple initial fetches, not to block refresh on state changes
    if (!shouldRefresh(state)) return false;
    
    final bloc = context.read<B>();
    onRefresh(context, bloc);
    return true;
  }

  /// Fetches initial data if needed
  /// Returns true if fetch was triggered, false otherwise
  bool fetchInitialDataIfNeeded(BuildContext context, S currentState) {
    if (!isInitialState(currentState)) return false;
    
    final bloc = context.read<B>();
    onRefresh(context, bloc);
    return true;
  }
}

