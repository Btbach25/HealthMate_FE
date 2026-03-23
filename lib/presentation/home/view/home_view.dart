import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/home_bloc.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/medication_card.dart';
import '../widgets/notification_list.dart';
import '../widgets/stats_grid.dart';
import '../bloc/health_overview_bloc.dart';
import '../widgets/health_overview_section.dart';
import '../widgets/welcome_message.dart';
import '../bloc/device_health_cubit.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Timer? _pollTimer;

  void _startPolling(BuildContext context) {
    if (kIsWeb) return;
    final cubit = context.read<DeviceHealthCubit>();
    cubit.poll().then((_) => cubit.startPeriodicSync());
    _pollTimer?.cancel();
    // Re-fetch device data mỗi 5 phút (dữ liệu HealthKit/Health Connect không đổi liên tục)
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      cubit.poll();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    if (!kIsWeb) {
      context.read<DeviceHealthCubit>().stopPeriodicSync();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lấy User từ AuthBloc (Luôn đúng với phiên đăng nhập)
    // Giả sử AuthBloc đã emit AuthState.authenticated chứa user
    // final user = context.select((AuthBloc bloc) => bloc.state.user); 
    
    // Nếu bạn chưa muốn sửa AuthBloc, giữ nguyên logic cũ của bạn cũng được.
    // Dưới đây mình viết theo logic hiện tại của bạn (lấy user từ HomeData) 
    // nhưng thêm RefreshIndicator.

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.initial ||
              state.status == HomeStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.status == HomeStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage ?? 'Đã có lỗi xảy ra',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.read<HomeBloc>().add(FetchHomeData()),
                    child: const Text('Thử lại'),
                  )
                ],
              ),
            );
          }

          if (state.status == HomeStatus.loaded && state.homeData != null) {
            final homeData = state.homeData!;
            // Dùng user từ AuthBloc (đúng với tài khoản đăng nhập) cho lời chào và app bar
            final authUser = context.read<AuthBloc>().state.user;
            final displayUser = authUser.isNotEmpty ? authUser : homeData.user;
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.inputBackground,
              strokeWidth: 2.5,
              displacement: 64,
              onRefresh: () async {
                final bloc = context.read<HomeBloc>();
                bloc.add(FetchHomeData());
                
                await bloc.stream.firstWhere((s) => s.status != HomeStatus.loading);
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeAppBar(user: displayUser),
                        const SizedBox(height: 24),

                        WelcomeMessage(name: displayUser.name),
                        const SizedBox(height: 24),

                        // Provide HealthOverviewBloc — tự subscribe DeviceHealthCubit bên trong
                        BlocProvider<HealthOverviewBloc>(
                          create: (context) => HealthOverviewBloc(
                            repository: RepositoryProvider.of(context),
                            deviceCubit: context.read<DeviceHealthCubit>(),
                          ),
                          child: Builder(
                            builder: (innerContext) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _startPolling(innerContext),
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HealthOverviewSection(),
                                  const SizedBox(height: 24),
                                  StatsGrid(homeData: homeData),
                                  const SizedBox(height: 12),
                                  BlocBuilder<DeviceHealthCubit, DeviceHealthState>(
                                    builder: (context, dState) {
                                      if (dState.lastUpdated == null) return const SizedBox.shrink();
                                      final ts = dState.lastUpdated!;
                                      final time = '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          'Đồng bộ thiết bị: ${dState.dataCount} mục, bước hôm nay: ${dState.totalSteps ?? '—'} (lúc $time)',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Health score card — luôn hiển thị
                        BlocBuilder<DeviceHealthCubit, DeviceHealthState>(
                          builder: (context, dState) {
                            if (dState.readinessLoading) return _ReadinessLoadingCard();
                            return _ReadinessScoreCard(score: dState.readinessScore);
                          },
                        ),

                        const SizedBox(height: 16),

                        if (homeData.medicationProgress != null)
                          MedicationCard(progress: homeData.medicationProgress!),
                        
                        const SizedBox(height: 24),

                        NotificationList(notifications: homeData.notifications),
                        
                        const SizedBox(height: 48), 
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return const Center(child: Text('Trạng thái không xác định'));
        },
      ),
    );
  }
}

class _ReadinessLoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Đang tính điểm sẵn sàng...', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ReadinessScoreCard extends StatelessWidget {
  final double? score;
  const _ReadinessScoreCard({required this.score});

  Color _scoreColor(double s) {
    if (s >= 75) return const Color(0xFF4CAF50);
    if (s >= 50) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  String _scoreLabel(double s) {
    if (s >= 75) return 'Tốt';
    if (s >= 50) return 'Trung bình';
    return 'Cần nghỉ ngơi';
  }

  String _moodAsset(double s) {
    if (s >= 75) return AppAssets.happy;
    if (s >= 50) return AppAssets.neutral;
    return AppAssets.sad;
  }

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null;
    final color = hasScore ? _scoreColor(score!) : AppColors.textGrey;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: hasScore
                    ? Text(
                        score!.toStringAsFixed(0),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                      )
                    : Icon(Icons.hourglass_empty, color: color, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Điểm sẵn sàng thể chất', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  hasScore ? _scoreLabel(score!) : 'Đang chờ dữ liệu thiết bị...',
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
            const Spacer(),
            hasScore
                ? Image.asset(
                    _moodAsset(score!),
                    width: 32,
                    height: 32,
                    color: color,
                    colorBlendMode: BlendMode.srcIn,
                  )
                : const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }
}