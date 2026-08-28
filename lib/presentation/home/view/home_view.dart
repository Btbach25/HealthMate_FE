import 'dart:async';

import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/models/health/stress_prediction.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';
import 'package:fe/presentation/home/bloc/health_overview_bloc.dart';
import 'package:fe/presentation/home/bloc/home_bloc.dart';
import 'package:fe/presentation/home/widgets/health_overview_section.dart';
import 'package:fe/presentation/home/widgets/medication_card.dart';
import 'package:fe/presentation/home/widgets/metric_carousel.dart';
import 'package:fe/presentation/home/widgets/notification_list.dart';
import 'package:fe/presentation/home/widgets/welcome_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Nội dung của tab "Tổng quan".
///
/// Render theo [HomeState] của [HomeBloc]: initial/loading -> spinner,
/// error -> card "Thử lại", loaded -> nội dung đầy đủ.
///
/// Widget này đồng thời sở hữu vòng đời việc đọc dữ liệu thiết bị:
/// nó gọi [DeviceHealthCubit.poll] định kỳ và [DeviceHealthCubit.stopPeriodicSync]
/// khi bị dispose. Trên web (`kIsWeb`) toàn bộ phần này bị bỏ qua vì
/// HealthKit/Health Connect không tồn tại.
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
    // Giữ lại tham chiếu cubit ngay từ đây vì trong dispose() không được phép
    // đụng vào context nữa, mà dispose() lại cần gọi stopPeriodicSync().
    _deviceHealthCubit ??= context.read<DeviceHealthCubit>();
  }

  void _startPolling() {
    if (kIsWeb) return;
    final cubit = _deviceHealthCubit;
    if (cubit == null) return;
    cubit.poll().then((_) => cubit.startPeriodicSync());
    _pollTimer?.cancel();
    // 5 phút, không ngắn hơn: startPeriodicSync() đã lo phần đọc lại Health Connect
    // và đẩy WebSocket ở tần suất giây. Timer này tồn tại để chạy lại poll(), tức là
    // gọi lại API readiness + stress — hai API tốn kém và có kết quả gần như không đổi
    // trong vài phút, nên gọi dày hơn chỉ đốt pin và quota.
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
            // Ưu tiên user từ AuthBloc: HomeData hiện do MockHomeService sinh ra nên
            // user trong đó không phải tài khoản đang đăng nhập. Chỉ fallback về
            // homeData.user khi AuthBloc chưa có user (ví dụ vừa khôi phục phiên).
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

                        // HealthOverviewBloc phải nằm ở đây (không phải app-level) vì nó
                        // subscribe stream của DeviceHealthCubit trong constructor và huỷ
                        // subscription trong close() — scope theo màn hình để tránh rò rỉ.
                        BlocProvider<HealthOverviewBloc>(
                          create: (context) => HealthOverviewBloc(
                            repository: RepositoryProvider.of(context),
                            deviceCubit: context.read<DeviceHealthCubit>(),
                          ),
                          child: Builder(
                            builder: (innerContext) {
                              // Chỉ khởi động polling đúng một lần cho cả vòng đời
                              // widget: builder này chạy lại mỗi lần rebuild, và phải
                              // hoãn sang post-frame vì không được start side-effect
                              // ngay trong build().
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

/// Placeholder trong lúc chờ điểm sẵn sàng (readiness) từ BE hoặc từ công thức cục bộ.
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

/// Thẻ hiển thị điểm sẵn sàng thể chất (thang 0-100).
///
/// [score] null nghĩa là chưa đủ số liệu đầu vào (thiếu nhịp tim), không phải lỗi —
/// nên card vẫn hiển thị chứ không biến mất.
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

/// Placeholder trong lúc gọi API dự đoán mức độ căng thẳng.
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

/// Thẻ hiển thị mức độ căng thẳng kèm cảnh báo về chất lượng dữ liệu đầu vào.
///
/// Ba trạng thái "không có kết quả" khác nhau, đừng gộp lại:
/// - [apiUnavailable] true : gọi API dự đoán thất bại.
/// - [prediction] null     : thiếu dữ liệu nhịp tim nên không gọi API.
/// - [dataEstimated] true  : có kết quả, nhưng RMSSD được ước tính từ độ lệch
///   chuẩn của nhịp tim (thiết bị không cung cấp HRV) nên độ tin cậy thấp hơn.
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