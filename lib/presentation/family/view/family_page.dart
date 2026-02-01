import 'package:fe/core/utils/bloc_refresh_helper.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/view/family_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  bool _hasInitialized = false;

  // Reusable refresh helper for family groups
  static final _refreshHelper = BlocRefreshHelper<FamilyBloc, FamilyState>(
    refreshTriggerStates: {
      FamilyStatus.groupDetailsLoaded,
      FamilyStatus.memberInvited,
      FamilyStatus.memberRemoved,
      FamilyStatus.groupUpdated,
      FamilyStatus.ownershipTransferred,
      FamilyStatus.groupLeft,
      FamilyStatus.invitationAccepted,
      FamilyStatus.invitationDeclined,
    },
    onRefresh: (context, bloc) => bloc.add(const FetchFamilyGroups()),
    initialState: FamilyStatus.initial,
    statusExtractor: (state) => state.status,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        final wasFetched = _refreshHelper.fetchInitialDataIfNeeded(
          context,
          context.read<FamilyBloc>().state,
        );
        if (wasFetched) _hasInitialized = true;
      }
    });
  }

  void _handleStateChange(FamilyState state) {
    if (!mounted) return;
    
    final wasRefreshed = _refreshHelper.handleStateChange(
      context,
      state,
      _hasInitialized,
    );
    if (wasRefreshed) _hasInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<FamilyBloc>(),
      child: BlocListener<FamilyBloc, FamilyState>(
        listener: (context, state) => _handleStateChange(state),
        child: const FamilyView(),
      ),
    );
  }
}
