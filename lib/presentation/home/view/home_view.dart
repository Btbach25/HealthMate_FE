import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_size.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/home_bloc.dart';
import '../widgets/medication_card.dart';
import '../widgets/notification_list.dart';
import '../bloc/health_overview_bloc.dart';
import '../widgets/health_overview_section.dart';
import '../widgets/welcome_message.dart';
import '../widgets/metric_carousel.dart';
import '../bloc/device_health_cubit.dart';
import '../../../data/models/health/stress_prediction.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Timer? _pollTimer;
  DeviceHealthCubit? _deviceHealthCubit;
  bool _syncStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deviceHealthCubit ??= context.read<DeviceHealthCubit>();
  }

  void _startPolling() {
    if (kIsWeb) return;
    final cubit = _deviceHealthCubit;
    if (cubit == null) return;
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
    if (!kIsWeb) _deviceHealthCubit?.stopPeriodicSync();
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải dữ liệu sức khỏe...',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (state.status == HomeStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.errorLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không tải được dữ liệu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textBlack),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'Vui lòng kiểm tra kết nối mạng và thử lại.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<HomeBloc>().add(FetchHomeData()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
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
                  constraints: const BoxConstraints(maxWidth: AppSize.shellMaxWidth),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              if (!_syncStarted) {
                                _syncStarted = true;
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  _startPolling();
                                });
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HealthOverviewSection(),
                                  const SizedBox(height: 16),
                                  const MetricCarousel(),
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

                        const SizedBox(height: 8),

                        BlocBuilder<DeviceHealthCubit, DeviceHealthState>(
                          builder: (context, dState) {
                            if (dState.stressLoading) return _StressLoadingCard();
                            return _StressCard(
                              prediction: dState.stressPrediction,
                              dataEstimated: dState.stressDataEstimated,
                              apiUnavailable: dState.stressApiError,
                            );
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
                  hasScore ? _scoreLabel(score!) : 'Đang chờ số liệu cập nhật...',
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

class _StressLoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Đang phân tích mức độ căng thẳng...', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _StressCard extends StatelessWidget {
  final StressPrediction? prediction;
  final bool dataEstimated;
  final bool apiUnavailable;
  const _StressCard({required this.prediction, this.dataEstimated = false, this.apiUnavailable = false});

  Color _color(StressPrediction p) {
    if (!p.isStress) return const Color(0xFF4CAF50);
    if (p.probStress >= 0.7) return const Color(0xFFF44336);
    return const Color(0xFFFFC107);
  }

  String _label(StressPrediction p) {
    if (!p.isStress) return 'Bình thường';
    if (p.probStress >= 0.7) return 'Đang căng thẳng';
    return 'Có thể căng thẳng';
  }

  IconData _icon(StressPrediction p) {
    if (!p.isStress) return Icons.sentiment_satisfied_alt;
    if (p.probStress >= 0.7) return Icons.sentiment_very_dissatisfied;
    return Icons.sentiment_neutral;
  }

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    final hasData = p != null;
    final color = hasData ? _color(p) : AppColors.textGrey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: hasData
                        ? Text(
                            '${(p.probStress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                          )
                        : Icon(apiUnavailable ? Icons.cloud_off_outlined : Icons.psychology_outlined, color: color, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mức độ căng thẳng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        hasData
                            ? _label(p)
                            : apiUnavailable
                                ? 'Dịch vụ phân tích chưa sẵn sàng'
                                : 'Chưa đủ dữ liệu (cần nhịp tim)',
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                    ],
                  ),
                ),
                if (hasData) Icon(_icon(p), color: color, size: 28),
              ],
            ),
            if (hasData && (dataEstimated || !p.calibrated)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 13, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text(
                    dataEstimated
                        ? 'HRV không có — dùng dữ liệu HR để ước tính'
                        : 'Kết quả chưa được hiệu chỉnh cá nhân',
                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}