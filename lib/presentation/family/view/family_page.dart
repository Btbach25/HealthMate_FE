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

  @override
  void initState() {
    super.initState();
    // Fetch groups when page is initialized - only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        final bloc = context.read<FamilyBloc>();
        final state = bloc.state;
        // Only fetch if initial state or if we need to refresh after certain actions
        if (state.status == FamilyStatus.initial) {
          bloc.add(const FetchFamilyGroups());
          _hasInitialized = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<FamilyBloc>(),
      child: BlocListener<FamilyBloc, FamilyState>(
        listener: (context, state) {
          // Refresh when returning from certain actions
          if (!_hasInitialized && mounted) {
            if (state.status == FamilyStatus.groupDetailsLoaded ||
                state.status == FamilyStatus.memberInvited ||
                state.status == FamilyStatus.memberRemoved ||
                state.status == FamilyStatus.groupUpdated ||
                state.status == FamilyStatus.ownershipTransferred ||
                state.status == FamilyStatus.groupLeft ||
                state.status == FamilyStatus.invitationAccepted ||
                state.status == FamilyStatus.invitationDeclined) {
              context.read<FamilyBloc>().add(const FetchFamilyGroups());
              _hasInitialized = true;
            }
          }
        },
        child: const FamilyView(),
      ),
    );
  }
}
