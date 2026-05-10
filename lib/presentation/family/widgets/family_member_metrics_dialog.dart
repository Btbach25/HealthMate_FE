import 'dart:async';

import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/metric_helper.dart';
import 'package:fe/core/utils/metric_selection_helper.dart';
import 'package:fe/core/utils/string_helper.dart';
import 'package:fe/core/utils/user_id_utils.dart';
import 'package:fe/core/widgets/loading_widget.dart';
import 'package:fe/core/widgets/settings_dropdown.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/details/metric_chart.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/health_status_extension.dart';
import 'package:fe/data/repositories/stats_repository.dart';
import 'package:fe/data/services/health_ws_service.dart';
import 'package:fe/presentation/details/widgets/stats_chart_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class FamilyMemberMetricsDialog extends StatefulWidget {
  final FamilyMember member;
  final String groupId;
  final StatsRepository statsRepository;

  const FamilyMemberMetricsDialog({
    super.key,
    required this.member,
    required this.groupId,
    required this.statsRepository,
  });

  static Future<void> show({
    required BuildContext context,
    required FamilyMember member,
    required String groupId,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FamilyMemberMetricsDialog(
        member: member,
        groupId: groupId,
        statsRepository: ctx.read<StatsRepository>(),
      ),
    );
  }

  @override
  State<FamilyMemberMetricsDialog> createState() =>
      _FamilyMemberMetricsDialogState();
}

class _FamilyMemberMetricsDialogState extends State<FamilyMemberMetricsDialog> {
  static const _allMetricsLabel = 'Tất cả chỉ số';

  late final List<String> _metricItems;
  late final List<String> _sharedMetricValuesForWs;
  /// Thứ tự cố định để chip realtime ổn định; đã lọc theo metric BE hỗ trợ.
  late final List<String> _watchedBackendMetrics;

  HealthWsService? _healthWs;
  StreamSubscription<FamilyMetricWatchEvent>? _realtimeSub;
  final Map<String, FamilyMetricWatchEvent> _liveByBackendMetric = {};

  // Dropdown state
  String _selectedMetric = _allMetricsLabel;
  String _selectedRange = '7 ngày qua';
  String _selectedSort = 'Mới nhất';

  // Charts future — rebuilt khi filter thay đổi
  late Future<List<MetricChart>> _chartsFuture;

  @override
  void initState() {
    super.initState();
    final sharedLabels =
        widget.member.sharedMetrics
            .map((t) => MetricHelper.getMetricOption(t).label)
            .toSet()
            .toList()
          ..sort();
    _metricItems = [_allMetricsLabel, ...sharedLabels];
    _sharedMetricValuesForWs =
        widget.member.sharedMetrics.map((t) => t.value).toList();
    _watchedBackendMetrics = MetricSelectionHelper.filterMetricTypesForBackend(
      _sharedMetricValuesForWs,
    )..sort();
    _chartsFuture = _loadCharts();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachRealtime());
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    if (!kIsWeb && _healthWs != null && _watchedBackendMetrics.isNotEmpty) {
      _healthWs!.unsubscribeFamilyMemberMetrics(
        targetUserId: widget.member.userId,
        groupId: widget.groupId,
        metricTypeValues: _sharedMetricValuesForWs,
      );
    }
    super.dispose();
  }

  void _attachRealtime() {
    if (kIsWeb || !mounted || _watchedBackendMetrics.isEmpty) return;
    final ws = context.read<HealthWsService>();
    _healthWs = ws;
    ws.subscribeFamilyMemberMetrics(
      targetUserId: widget.member.userId,
      groupId: widget.groupId,
      metricTypeValues: _sharedMetricValuesForWs,
    );
    _realtimeSub = ws.watchStream.listen((e) {
      if (!sameUserId(e.ownerUserId, widget.member.userId)) return;
      if (!_watchedBackendMetrics.contains(e.metricType)) return;
      if (!mounted) return;
      setState(() => _liveByBackendMetric[e.metricType] = e);
    });
  }

  String _labelForBackendMetric(String backend) {
    try {
      final t = MetricType.fromValue(backend);
      return MetricHelper.getMetricOption(t).label;
    } catch (_) {
      return backend;
    }
  }

  String _formatLiveValue(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  /// Map nhãn hiển thị → range param cho API
  String _rangeParam(String label) {
    switch (label) {
      case '24 giờ qua':
        return '24h';
      case '30 ngày qua':
        return '30d';
      default:
        return '7d';
    }
  }

  Future<List<MetricChart>> _loadCharts() {
    // Lấy danh sách metric type (value string) để filter
    final allSharedTypes = widget.member.sharedMetrics
        .map((t) => t.value)
        .toList();

    List<String>? filterTypes;
    if (_selectedMetric != _allMetricsLabel) {
      // Tìm MetricType có label khớp
      final matchedType = widget.member.sharedMetrics.where((t) {
        return MetricHelper.getMetricOption(t).label == _selectedMetric;
      });
      filterTypes = matchedType.map((t) => t.value).toList();
    } else {
      filterTypes = allSharedTypes.isEmpty ? null : allSharedTypes;
    }

    return widget.statsRepository.getChartDataForMember(
      widget.member.userId,
      range: _rangeParam(_selectedRange),
      filterMetricTypes: filterTypes,
    );
  }

  void _applyFilter() {
    setState(() {
      _chartsFuture = _loadCharts();
    });
  }

  List<MetricChart> _sortCharts(List<MetricChart> charts) {
    final sorted = [...charts];
    if (_selectedSort == 'Cũ nhất') {
      for (final c in sorted) {
        c.points.sort((a, b) => a.time.compareTo(b.time));
      }
    } else {
      for (final c in sorted) {
        c.points.sort((a, b) => b.time.compareTo(a.time));
      }
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.member.healthStatus.color;
    final statusBgColor = widget.member.healthStatus.backgroundColor;
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxDialogHeight),
        child: Padding(
          padding: const EdgeInsets.all(AppSize.p20),
          child: ScrollConfiguration(
            behavior: const _FamilyMetricsDialogScrollBehavior(),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // ── Header ──────────────────────────────────────────────
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
                          [
                            if (widget.member.relationship != null)
                              widget.member.relationship!,
                            if (widget.member.age != null)
                              '${widget.member.age} tuổi',
                          ].join(' • '),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
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
                                'Chia sẻ ${widget.member.sharedMetrics.length} chỉ số',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey.withValues(
                                    alpha: 0.8,
                                  ),
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

              // ── Filter row ──────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bộ lọc và sắp xếp dữ liệu',
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useRow = constraints.maxWidth >= 420;
                  final dropdowns = [
                    SettingsDropdown(
                      label: 'Loại chỉ số',
                      value: _selectedMetric,
                      items: _metricItems,
                      onChanged: (v) {
                        if (v == null) return;
                        _selectedMetric = v;
                        _applyFilter();
                      },
                    ),
                    SettingsDropdown(
                      label: 'Thời gian',
                      value: _selectedRange,
                      items: const ['24 giờ qua', '7 ngày qua', '30 ngày qua'],
                      onChanged: (v) {
                        if (v == null) return;
                        _selectedRange = v;
                        _applyFilter();
                      },
                    ),
                    SettingsDropdown(
                      label: 'Sắp xếp',
                      value: _selectedSort,
                      items: const ['Mới nhất', 'Cũ nhất'],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedSort = v);
                      },
                    ),
                  ];
                  if (useRow) {
                    return Row(
                      children: [
                        Expanded(child: dropdowns[0]),
                        const SizedBox(width: 8),
                        Expanded(child: dropdowns[1]),
                        const SizedBox(width: 8),
                        Expanded(child: dropdowns[2]),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      dropdowns[0],
                      const SizedBox(height: 8),
                      dropdowns[1],
                      const SizedBox(height: 8),
                      dropdowns[2],
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Mobile: cập nhật số liệu mới (web chỉ có biểu đồ lịch sử).
              if (!kIsWeb && _watchedBackendMetrics.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Số liệu mới nhất',
                    style: AppTextStyles.h4.copyWith(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _watchedBackendMetrics.map((backend) {
                    final ev = _liveByBackendMetric[backend];
                    final label = _labelForBackendMetric(backend);
                    if (ev == null) {
                      return Chip(
                        label: Text(
                          '$label: —',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppColors.inputBackground,
                        side: BorderSide(color: AppColors.cardBorder),
                        visualDensity: VisualDensity.compact,
                      );
                    }
                    final timeStr = DateFormat(
                      'dd/MM HH:mm',
                    ).format(ev.timestamp.toLocal());
                    return Chip(
                      avatar: Icon(
                        Icons.bolt_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        '$label: ${_formatLiveValue(ev.value)} · $timeStr',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                if (_liveByBackendMetric.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Chưa có số liệu mới. Khi thành viên có đo mới, bạn sẽ thấy tại đây.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ] else if (kIsWeb && _watchedBackendMetrics.isNotEmpty) ...[
                Text(
                  'Trên trình duyệt, bạn xem biểu đồ theo khoảng thời gian đã chọn. '
                  'Để theo dõi số liệu cập nhật nhanh hơn, hãy mở ứng dụng trên điện thoại.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Record count ─────────────────────────────────────────
              FutureBuilder<List<MetricChart>>(
                future: _chartsFuture,
                builder: (context, snapshot) {
                  final pointsCount = (snapshot.data ?? []).fold<int>(
                    0,
                    (sum, c) => sum + c.points.length,
                  );
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Trong $_selectedRange: $pointsCount lần ghi nhận',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Charts (scroll cùng toàn bộ dialog — tránh overflow khi màn hình thấp / web) ──
              FutureBuilder<List<MetricChart>>(
                future: _chartsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: LoadingWidget(),
                    );
                  }
                  if (snapshot.hasError) {
                    return _EmptyState(
                      rangeLabel: _selectedRange,
                      errorMessage: 'Không thể tải dữ liệu. Thử lại sau.',
                    );
                  }
                  final charts = _sortCharts(snapshot.data ?? []);
                  if (charts.isEmpty) {
                    return _EmptyState(rangeLabel: _selectedRange);
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: charts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => StatsChartCard(
                      chart: charts[index],
                      selectedRange: _rangeParam(_selectedRange),
                    ),
                  );
                },
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuộn khi nội dung dài; không vẽ thanh scrollbar mặc định (web/desktop hay hiện thanh dày dù ít nội dung).
class _FamilyMetricsDialogScrollBehavior extends ScrollBehavior {
  const _FamilyMetricsDialogScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _EmptyState extends StatelessWidget {
  final String rangeLabel;
  final String? errorMessage;
  const _EmptyState({required this.rangeLabel, this.errorMessage});

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
          const Icon(
            Icons.bar_chart_rounded,
            size: 56,
            color: AppColors.textGrey,
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Không có dữ liệu phù hợp',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage != null
                ? 'Kiểm tra kết nối hoặc thử lại.'
                : 'Hãy thử thay đổi bộ lọc để xem dữ liệu khác.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
