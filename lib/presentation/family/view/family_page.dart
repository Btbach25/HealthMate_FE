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

  // Cache bloc references để tránh context.read() lúc element đang inactive
  // (giữa deactivate() và unmount() — lúc này mounted = true nhưng ancestor lookup fail).
  AuthBloc? _authBloc;
  FamilyBloc? _familyBloc;

  static final _refreshHelper = BlocRefreshHelper<FamilyBloc, FamilyState>(
    refreshTriggerStates: {},
    onRefresh: (context, bloc) => bloc.add(const FetchFamilyGroups()),
    initialState: FamilyStatus.initial,
    statusExtractor: (state) => state.status,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lưu tham chiếu lúc element đang active — dùng trong callbacks sau này.
    _authBloc = context.read<AuthBloc>();
    _familyBloc = context.read<FamilyBloc>();
  }

  /// Chỉ fetch lần đầu khi đã đăng nhập.
  void _tryInitialFetch() {
    if (_hasInitialized || !mounted) return;
    final authBloc = _authBloc;
    final familyBloc = _familyBloc;
    if (authBloc == null || familyBloc == null) return;
    if (authBloc.state.status != AuthStatus.authenticated) return;
    if (!_refreshHelper.isInitialState(familyBloc.state)) return;

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final bloc = _familyBloc;
      if (bloc == null) return;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryInitialFetch());
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
        listenWhen: (prev, curr) =>
            curr.status == AuthStatus.authenticated &&
            prev.status != AuthStatus.authenticated,
        listener: (context, authState) {
          if (!mounted) return;
          setState(() => _hasInitialized = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _tryInitialFetch();
          });
        },
        child: BlocListener<FamilyBloc, FamilyState>(
          listener: (context, state) => _handleStateChange(state),
          child: const FamilyView(),
        ),
      ),
    );
  }
}
