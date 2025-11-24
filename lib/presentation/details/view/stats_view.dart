import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/presentation/details/bloc/stats_bloc.dart';
import 'package:fe/presentation/details/widgets/stats_chart_lazy_loader.dart';
import 'package:fe/presentation/details/widgets/stats_header_card.dart';
import 'package:fe/presentation/details/widgets/stats_metric_list.dart';
import 'package:fe/presentation/details/widgets/stats_tab_bar.dart';
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
      body: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          if (state.status == StatsStatus.initial ||
              state.status == StatsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == StatsStatus.error) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Đã có lỗi xảy ra',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          if (state.status == StatsStatus.loaded && state.statsData != null) {
            final data = state.statsData!;

            // Bố cục chính của trang
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                // NestedScrollView để header cuộn cùng với list
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      // SliverAppBar chứa Header, Buttons, và TabBar
                      SliverAppBar(
                        backgroundColor: AppColors.background,
                        pinned: true, // Ghim TabBar ở trên cùng
                        automaticallyImplyLeading: false, // Bỏ nút back
                        flexibleSpace: FlexibleSpaceBar(
                          // Dùng Column vì TabBar phải ở dưới cùng
                          background: Column(
                            children: [
                              // 1. Header Card
                              StatsHeaderCard(
                                totalReadings: data.totalReadings,
                                totalTypes: data.totalTypes,
                              ),
                              // 2. Action Buttons (Xem, Thêm)
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                        // Đặt TabBar vào bottom của SliverAppBar
                        bottom: StatsTabBar(controller: _tabController),
                        // Tính toán chiều cao
                        expandedHeight: 280, // Chiều cao dự kiến
                      ),
                    ];
                  },
                  // Nội dung của TabBarView
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Gần đây
                      StatsMetricList(
                        metrics: data.metrics,
                        displayMode: MetricDisplayMode.trend,
                      ),
                      // Tab 2: Tổng quan
                      StatsMetricList(
                        metrics: data.metrics,
                        displayMode: MetricDisplayMode.status,
                      ),
                      
                      // --- THAY ĐỔI TAB 3: BIỂU ĐỒ ---
                      // Widget này sẽ tự lazy-load BLoC
                      const StatsChartLazyLoader(),
                    ],
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

  /// Widget con cho 2 nút "Xem chi tiết" và "Thêm chỉ số"
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        children: [
          // Nút 1: Xem chi tiết
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Xem chi tiết'),
              onPressed: () {
                // TODO: Xử lý sự kiện
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: AppColors.textBlack,
                side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Nút 2: Thêm chỉ số
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm chỉ số'),
              onPressed: () {
                // TODO: Xử lý sự kiện
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}