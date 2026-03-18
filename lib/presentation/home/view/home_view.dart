import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
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
            final user = homeData.user;
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeAppBar(user: user),
                        const SizedBox(height: 24),

                        WelcomeMessage(name: user.name),
                        const SizedBox(height: 24),

                        // Provide HealthOverviewBloc; DeviceHealthCubit comes from app-level provider
                        BlocProvider<HealthOverviewBloc>(
                          create: (context) => HealthOverviewBloc(
                            repository: RepositoryProvider.of(context),
                          ),
                          child: Builder(
                            builder: (innerContext) {
                              // Start polling after first frame
                              WidgetsBinding.instance.addPostFrameCallback((_) => _startPolling(innerContext));
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HealthOverviewSection(),
                                  const SizedBox(height: 24),
                                  StatsGrid(homeData: homeData),
                                  const SizedBox(height: 12),
                                  BlocBuilder<DeviceHealthCubit, DeviceHealthState>(
                                    builder: (context, dState) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Readiness Score card
                                          if (dState.readinessLoading)
                                            _ReadinessLoadingCard()
                                          else if (dState.readinessScore != null)
                                            _ReadinessScoreCard(score: dState.readinessScore!),

                                          if (dState.lastUpdated != null) ...[
                                            const SizedBox(height: 6),
                                            Builder(builder: (_) {
                                              final ts = dState.lastUpdated!;
                                              final time = '${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}';
                                              return Text(
                                                'Đồng bộ thiết bị: ${dState.dataCount} mục, bước hôm nay: ${dState.totalSteps ?? '—'} (lúc $time)',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                                              );
                                            }),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

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
  final double score;
  const _ReadinessScoreCard({required this.score});

  Color _scoreColor() {
    if (score >= 75) return const Color(0xFF4CAF50);
    if (score >= 50) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  String _scoreLabel() {
    if (score >= 75) return 'Tốt';
    if (score >= 50) return 'Trung bình';
    return 'Cần nghỉ ngơi';
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
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
                child: Text(
                  score.toStringAsFixed(0),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Điểm sẵn sàng thể chất', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_scoreLabel(), style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
            const Spacer(),
            Icon(Icons.bolt_rounded, color: color),
          ],
        ),
      ),
    );
  }
}