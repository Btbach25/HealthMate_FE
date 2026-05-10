import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/presentation/details/bloc/stats_bloc.dart';
import 'package:fe/presentation/details/widgets/stats_chart_lazy_loader.dart';
import 'package:fe/presentation/details/widgets/stats_header_card.dart';
import 'package:fe/presentation/details/widgets/stats_metric_list.dart';
import 'package:fe/presentation/details/widgets/stats_tab_bar.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  static String _rangeLabel(String range) {
    switch (range) {
      case '24h': return '24 giờ';
      case '7d':  return '7 ngày';
      case '30d': return '30 ngày';
      default:    return range;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải chỉ số sức khỏe...',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            if (state.status == StatsStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 48, color: AppColors.textGrey),
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

            if (state.status == StatsStatus.loaded &&
                state.statsData != null &&
                state.statsData!.metrics.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<StatsBloc>().add(FetchStatsData());
                  await context
                      .read<StatsBloc>()
                      .stream
                      .firstWhere((s) => s.status != StatsStatus.loading);
                },
                child: ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monitor_heart_outlined,
                                size: 48, color: AppColors.textGrey),
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
                onRefresh: () async {
                  context.read<StatsBloc>().add(FetchStatsData());
                  await context
                      .read<StatsBloc>()
                      .stream
                      .firstWhere((s) => s.status != StatsStatus.loading);
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: NestedScrollView(
                      headerSliverBuilder:
                          (context, innerBoxIsScrolled) {
                        return [
                          SliverAppBar(
                            backgroundColor: AppColors.surface,
                            pinned: true,
                            automaticallyImplyLeading: false,
                            toolbarHeight: 0,
                            flexibleSpace: FlexibleSpaceBar(
                              collapseMode: CollapseMode.pin,
                              background: Container(
                                color: AppColors.surface,
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title row — fixed at the top of the background
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.warningLight,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.smartphone,
                                                    size: 11,
                                                    color: AppColors.warning),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Thiết bị',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.warning,
                                                      fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        PopupMenuButton<String>(
                                          initialValue: state.selectedRange,
                                          onSelected: (range) => context
                                              .read<StatsBloc>()
                                              .add(ChangeStatsRange(range)),
                                          offset: const Offset(0, 38),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          elevation: 3,
                                          itemBuilder: (_) =>
                                              StatsState.availableRanges.map((r) {
                                            final active = r == state.selectedRange;
                                            return PopupMenuItem<String>(
                                              value: r,
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    child: active
                                                        ? const Icon(Icons.check,
                                                            size: 16,
                                                            color: AppColors.primary)
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _rangeLabel(r),
                                                    style: TextStyle(
                                                      fontWeight: active
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: active
                                                          ? AppColors.primary
                                                          : AppColors.textBlack,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryContainer,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _rangeLabel(state.selectedRange),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 3),
                                                const Icon(
                                                  Icons.keyboard_arrow_down_rounded,
                                                  color: AppColors.primary,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ),
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
