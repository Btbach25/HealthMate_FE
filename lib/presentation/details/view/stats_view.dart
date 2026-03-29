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
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == StatsStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textGrey),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Không thể tải dữ liệu',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.read<StatsBloc>().add(FetchStatsData()),
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

          if (state.status == StatsStatus.loaded && state.statsData != null && state.statsData!.metrics.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<StatsBloc>().add(FetchStatsData());
                await context.read<StatsBloc>().stream
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
                          Icon(Icons.monitor_heart_outlined, size: 48, color: AppColors.textGrey),
                          SizedBox(height: 12),
                          Text(
                            'Chưa có dữ liệu sức khỏe từ máy chủ.\nKéo xuống để tải lại.',
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

            // Bố cục chính của trang
            return RefreshIndicator(
              onRefresh: () async {
                context.read<StatsBloc>().add(FetchStatsData());
                await context.read<StatsBloc>().stream
                    .firstWhere((s) => s.status != StatsStatus.loading);
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  // NestedScrollView để header cuộn cùng với list
                  child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      // SliverAppBar chứa Header, Buttons, và TabBar
                      SliverAppBar(
                        backgroundColor: AppColors.background,
                        pinned: true,
                        automaticallyImplyLeading: false,
                        titleSpacing: 0,
                        title: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text(
                                'Chỉ số sức khỏe',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (state.isFromDevice) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.smartphone, size: 12, color: Colors.orange.shade700),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Thiết bị',
                                        style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          background: SafeArea(
                            bottom: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 56), // chừa chỗ cho title
                                StatsHeaderCard(
                                  totalReadings: data.totalReadings,
                                  totalTypes: data.totalTypes,
                                ),
                                _buildRangeSelector(context, state.selectedRange),
                              ],
                            ),
                          ),
                        ),
                        bottom: StatsTabBar(controller: _tabController),
                        expandedHeight: 300,
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

  Widget _buildRangeSelector(BuildContext context, String selectedRange) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: StatsState.availableRanges.map((range) {
          final isSelected = range == selectedRange;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: range != StatsState.availableRanges.last ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () => context.read<StatsBloc>().add(ChangeStatsRange(range)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    range,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textBlack,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}