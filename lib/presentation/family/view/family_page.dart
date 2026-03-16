import 'package:fe/core/utils/bloc_refresh_helper.dart';
import 'package:fe/data/repositories/auth_repository.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
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

  // Reusable refresh helper for family groups.
  // Không gồm groupDetailsLoaded để tránh gọi GET /groups khi user đang xem chi tiết nhóm (gây một đống request).
  static final _refreshHelper = BlocRefreshHelper<FamilyBloc, FamilyState>(
    // Tránh auto-fetch trùng với logic trong FamilyBloc (dễ gây race và ghi đè state).
    refreshTriggerStates: {},
    onRefresh: (context, bloc) => bloc.add(const FetchFamilyGroups()),
    initialState: FamilyStatus.initial,
    statusExtractor: (state) => state.status,
  );

    /// Chỉ fetch lần đầu khi đã đăng nhập. Trì hoãn để storage (token) sẵn sàng trên web, tránh 401.
    void _tryInitialFetch(BuildContext context) {
    if (_hasInitialized || !mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated) return;
    final familyState = context.read<FamilyBloc>().state;
    if (!_refreshHelper.isInitialState(familyState)) return;

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final bloc = context.read<FamilyBloc>();
      final wasFetched = _refreshHelper.fetchInitialDataIfNeeded(
        context,
        bloc.state,
      );
      if (wasFetched) _hasInitialized = true;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryInitialFetch(context));
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
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState.status == AuthStatus.authenticated) {
            _tryInitialFetch(context);
          }
        },
        child: BlocListener<FamilyBloc, FamilyState>(
          listener: (context, state) => _handleStateChange(state),
          child: const FamilyView(),
        ),
      ),
    );
  }
}
