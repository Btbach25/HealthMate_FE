import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/presentation/details/bloc/stats_bloc.dart';
import 'package:fe/presentation/details/widgets/stats_chart_lazy_loader.dart';
import 'package:fe/presentation/details/widgets/stats_device_badge.dart';
import 'package:fe/presentation/details/widgets/stats_header_card.dart';
import 'package:fe/presentation/details/widgets/stats_metric_list.dart';
import 'package:fe/presentation/details/widgets/stats_range_menu.dart';
import 'package:fe/presentation/details/widgets/stats_tab_bar.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Giao diện màn Chỉ số sức khỏe. Phải nằm dưới `BlocProvider<StatsBloc>` —
/// `StatsPage` lo việc đó.
///
/// Là StatefulWidget chỉ vì cần sở hữu `TabController` cho 3 tab
/// (Gần đây / Tổng quan / Biểu đồ); mọi dữ liệu đều đến từ [StatsBloc].
class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Không đọc context trong initState được, nên hoãn tới sau frame đầu.
    // Mục đích: nếu cảm biến đã có sẵn điểm đo từ trước khi mở màn này, dùng
    // luôn thay vì chờ DeviceHealthCubit phát state mới (có thể không bao giờ).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final deviceCubit = context.read<DeviceHealthCubit>();
      if (deviceCubit.lastPoints.isNotEmpty) {
        context.read<StatsBloc>().add(TryDeviceFallback());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Kéo-để-làm-mới: bắn [FetchStatsData] rồi CHỜ bloc thoát trạng thái
  /// loading. Nếu không await, `RefreshIndicator` sẽ tắt vòng xoay ngay lập
  /// tức trong khi dữ liệu vẫn đang tải.
  Future<void> _refresh(BuildContext context) async {
    context.read<StatsBloc>().add(FetchStatsData());
    await context.read<StatsBloc>().stream.firstWhere(
      (s) => s.status != StatsStatus.loading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // listenWhen chỉ nhận khi số điểm đo TĂNG: DeviceHealthCubit phát state
      // khá thường xuyên, không lọc thì mỗi lần đều bắn một event vào bloc.
      body: BlocListener<DeviceHealthCubit, DeviceHealthState>(
        listenWhen: (prev, curr) => curr.dataCount > prev.dataCount,
        listener: (context, _) {
          if (!context.mounted) return;
          context.read<StatsBloc>().add(TryDeviceFallback());
        },
        child: BlocBuilder<StatsBloc, StatsState>(
          builder: (context, state) {
            if (state.status == StatsStatus.initial ||
                state.status == StatsStatus.loading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải chỉ số sức khỏe...',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            // Nhánh này gần như không xảy ra: StatsBloc nuốt lỗi mạng và trả
            // về danh sách rỗng thay vì StatsStatus.error. Giữ lại làm lưới an
            // toàn nếu sau này bloc bắt đầu emit lỗi.
            if (state.status == StatsStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage ?? 'Không thể tải dữ liệu',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.read<StatsBloc>().add(FetchStatsData()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Rỗng: bọc trong ListView để RefreshIndicator vẫn kéo được dù nội
            // dung ngắn hơn màn hình.
            if (state.status == StatsStatus.loaded &&
                state.statsData != null &&
                state.statsData!.metrics.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monitor_heart_outlined,
                              size: 48,
                              color: AppColors.textGrey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Chưa có số liệu để hiển thị.\nKéo xuống để tải lại.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state.status == StatsStatus.loaded && state.statsData != null) {
              final data = state.statsData!;

              return RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: Center(
                  // Giới hạn bề ngang để trên tablet/web nội dung không bị kéo
                  // dãn hết màn hình.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          SliverAppBar(
                            backgroundColor: AppColors.surface,
                            pinned: true,
                            automaticallyImplyLeading: false,
                            // toolbarHeight 0 + flexibleSpace: dùng SliverAppBar
                            // như một header cuộn được, không phải app bar thật.
                            // Chỉ thanh tab ở `bottom` được ghim lại.
                            toolbarHeight: 0,
                            flexibleSpace: FlexibleSpaceBar(
                              collapseMode: CollapseMode.pin,
                              background: Container(
                                color: AppColors.surface,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Chỉ số sức khỏe',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textBlack,
                                          ),
                                        ),
                                        if (state.isFromDevice) ...[
                                          const SizedBox(width: 8),
                                          const StatsDeviceBadge(),
                                        ],
                                        const Spacer(),
                                        StatsRangeMenu(
                                          selectedRange: state.selectedRange,
                                          ranges: StatsState.availableRanges,
                                          onSelected: (range) => context
                                              .read<StatsBloc>()
                                              .add(ChangeStatsRange(range)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    StatsHeaderCard(
                                      totalReadings: data.totalReadings,
                                      totalTypes: data.totalTypes,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            bottom: StatsTabBar(controller: _tabController),
                            expandedHeight: 160,
                          ),
                        ];
                      },
                      body: TabBarView(
                        controller: _tabController,
                        children: [
                          StatsMetricList(
                            metrics: data.metrics,
                            displayMode: MetricDisplayMode.trend,
                          ),
                          StatsMetricList(
                            metrics: data.metrics,
                            displayMode: MetricDisplayMode.status,
                          ),
                          const StatsChartLazyLoader(),
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
      ),
    );
  }
}
