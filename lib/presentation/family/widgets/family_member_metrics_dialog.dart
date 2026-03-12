import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/metric_helper.dart';
import 'package:fe/core/utils/string_helper.dart';
import 'package:fe/core/widgets/loading_widget.dart';
import 'package:fe/core/widgets/settings_dropdown.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/health_status_extension.dart';
import 'package:fe/data/services/mock_stats_service.dart';
import 'package:fe/presentation/details/widgets/stats_chart_card.dart';
import 'package:flutter/material.dart';

class FamilyMemberMetricsDialog extends StatefulWidget {
  final FamilyMember member;

  const FamilyMemberMetricsDialog({super.key, required this.member});

  static Future<void> show({
    required BuildContext context,
    required FamilyMember member,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => FamilyMemberMetricsDialog(member: member),
    );
  }

  @override
  State<FamilyMemberMetricsDialog> createState() =>
      _FamilyMemberMetricsDialogState();
}

class _FamilyMemberMetricsDialogState extends State<FamilyMemberMetricsDialog> {
  static const _allMetricsLabel = 'Tất cả chỉ số';

  late final MockStatsService _statsService;
  late final Future<List<MetricChart>> _chartsFuture;

  late final List<String> _metricItems;

  String _selectedMetric = _allMetricsLabel;
  String _selectedRange = '30 ngày qua';
  String _selectedSort = 'Mới nhất';

  @override
  void initState() {
    super.initState();
    _statsService = MockStatsService();
    _chartsFuture = _statsService.getChartData();

    final sharedLabels = widget.member.sharedMetrics
        .map((t) => MetricHelper.getMetricOption(t).label)
        .toSet()
        .toList()
      ..sort();
    _metricItems = [_allMetricsLabel, ...sharedLabels];
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.member.healthStatus.color;
    final statusBgColor = widget.member.healthStatus.backgroundColor;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSize.p20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        StringHelper.getInitials(widget.member.name),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.member.name, style: AppTextStyles.h4),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.member.relationship ?? ''}${widget.member.relationship != null && widget.member.age != null ? ' • ' : ''}${widget.member.age != null ? '${widget.member.age} tuổi' : ''}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.member.healthStatus.displayLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Dữ liệu được chia sẻ: ${widget.member.sharedMetrics.length} loại chỉ số',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bộ lọc và sắp xếp dữ liệu',
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SettingsDropdown(
                      label: 'Loại chỉ số',
                      value: _selectedMetric,
                      items: _metricItems,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedMetric = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SettingsDropdown(
                      label: 'Khoảng thời gian',
                      value: _selectedRange,
                      items: const ['7 ngày qua', '30 ngày qua'],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedRange = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SettingsDropdown(
                      label: 'Sắp xếp theo',
                      value: _selectedSort,
                      items: const ['Mới nhất', 'Cũ nhất'],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedSort = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<MetricChart>>(
                future: _chartsFuture,
                builder: (context, snapshot) {
                  final charts = snapshot.data ?? const [];
                  final pointsCount = charts.fold<int>(
                    0,
                    (sum, c) => sum + c.points.length,
                  );
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hiển thị $pointsCount bản ghi trong $_selectedRange',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              Flexible(
                child: FutureBuilder(
                  future: _chartsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: LoadingWidget(),
                      );
                    }
                    final charts = snapshot.data ?? const [];
                    if (charts.isEmpty) {
                      return _EmptyState(rangeLabel: _selectedRange);
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: charts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          StatsChartCard(chart: charts[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String rangeLabel;
  const _EmptyState({required this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart_rounded, size: 56, color: AppColors.textGrey),
          const SizedBox(height: 12),
          const Text(
            'Không có dữ liệu phù hợp',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hãy thử thay đổi bộ lọc để xem dữ liệu khác.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '(Mock) $rangeLabel',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

