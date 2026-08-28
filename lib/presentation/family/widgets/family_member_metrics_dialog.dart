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

/// Dialog xem chỉ số sức khoẻ một thành viên đã chia sẻ. Mở từ nút "Xem chỉ số"
/// (hoặc "Theo dõi") trên thẻ thành viên ở màn chi tiết nhóm.
///
/// Chỉ hiển thị đúng những chỉ số trong `member.sharedMetrics` — màn gọi đã chặn
/// từ trước nếu danh sách rỗng. Không sửa được gì, chỉ để xem.
///
/// Biểu đồ lấy theo yêu cầu qua `StatsRepository.getChartDataForMember`. Trên
/// mobile còn cắm thêm luồng WebSocket để hiện số liệu mới nhất theo thời gian
/// thực; trên web thì bỏ qua (`kIsWeb`) và luôn nhớ huỷ đăng ký trong `dispose`.
///
/// Dùng [FamilyMemberMetricsDialog.show] để mở — hàm này lấy sẵn `StatsRepository`
/// từ context gọi, vì context bên trong dialog không nhìn thấy provider đó.
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

class _FamilyMemberMetricsDialogState
    extends State<FamilyMemberMetricsDialog> {
  static const _allMetricsLabel = 'Tất cả chỉ số';

  late final List<String> _metricItems;
  late final List<String> _sharedMetricValuesForWs;
  late final List<String> _watchedBackendMetrics;

  HealthWsService? _healthWs;
  StreamSubscription<FamilyMetricWatchEvent>? _realtimeSub;
  final Map<String, FamilyMetricWatchEvent> _liveByBackendMetric = {};

  String _selectedMetric = _allMetricsLabel;
  String _selectedRange = '7 ngày qua';
  String _selectedSort = 'Mới nhất';

  late Future<List<MetricChart>> _chartsFuture;

  @override
  void initState() {
    super.initState();
    final sharedLabels = widget.member.sharedMetrics
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
    final allSharedTypes =
        widget.member.sharedMetrics.map((t) => t.value).toList();
    List<String>? filterTypes;
    if (_selectedMetric != _allMetricsLabel) {
      filterTypes = widget.member.sharedMetrics
          .where((t) => MetricHelper.getMetricOption(t).label == _selectedMetric)
          .map((t) => t.value)
          .toList();
    } else {
      filterTypes = allSharedTypes.isEmpty ? null : allSharedTypes;
    }
    return widget.statsRepository.getChartDataForMember(
      widget.member.userId,
      range: _rangeParam(_selectedRange),
      filterMetricTypes: filterTypes,
    );
  }

  void _applyFilter() => setState(() => _chartsFuture = _loadCharts());

  List<MetricChart> _sortCharts(List<MetricChart> charts) {
    final sorted = [...charts];
    final asc = _selectedSort == 'Cũ nhất';
    for (final c in sorted) {
      c.points.sort(
        (a, b) => asc ? a.time.compareTo(b.time) : b.time.compareTo(a.time),
      );
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.9;
    final statusColor = widget.member.healthStatus.color;
    final statusBgColor = widget.member.healthStatus.backgroundColor;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r16),
      ),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxDialogHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header (fixed, không scroll) ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        StringHelper.getInitials(widget.member.name),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member.name,
                          style: AppTextStyles.h4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.member.relationship != null ||
                            widget.member.age != null)
                          Text(
                            [
                              if (widget.member.relationship != null)
                                widget.member.relationship!,
                              if (widget.member.age != null)
                                '${widget.member.age} tuổi',
                            ].join(' · '),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textGrey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Chip(
                              label: widget.member.healthStatus.displayLabel,
                              color: statusColor,
                              bgColor: statusBgColor,
                            ),
                            _Chip(
                              label:
                                  '${widget.member.sharedMetrics.length} chỉ số',
                              color: AppColors.textSecondary,
                              bgColor: AppColors.inputBackground,
                              icon: Icons.share_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Close
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.8, color: AppColors.cardBorder),

            // ── Scrollable body ───────────────────────────────────────
            Flexible(
              child: ScrollConfiguration(
                behavior: const _NoScrollbarBehavior(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Filters ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final useRow = constraints.maxWidth >= 380;
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
                                items: const [
                                  '24 giờ qua',
                                  '7 ngày qua',
                                  '30 ngày qua',
                                ],
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
                      ),
                      const SizedBox(height: 16),

                      // ── Live metrics (mobile only) ────────────────────
                      if (!kIsWeb && _watchedBackendMetrics.isNotEmpty) ...[
                        _SectionLabel(
                          icon: Icons.bolt_rounded,
                          iconColor: AppColors.primary,
                          label: 'Số liệu mới nhất',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _watchedBackendMetrics.map((backend) {
                            final ev = _liveByBackendMetric[backend];
                            final label = _labelForBackendMetric(backend);
                            if (ev == null) {
                              return _LiveChip(label: label, value: null);
                            }
                            final timeStr = DateFormat('HH:mm dd/MM')
                                .format(ev.timestamp.toLocal());
                            return _LiveChip(
                              label: label,
                              value: _formatLiveValue(ev.value),
                              time: timeStr,
                            );
                          }).toList(),
                        ),
                        if (_liveByBackendMetric.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Đang chờ cập nhật từ thành viên...',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // ── Record count + charts ─────────────────────────
                      FutureBuilder<List<MetricChart>>(
                        future: _chartsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: LoadingWidget(),
                            );
                          }
                          if (snapshot.hasError) {
                            return _EmptyState(
                              rangeLabel: _selectedRange,
                              errorMessage:
                                  'Không thể tải dữ liệu. Thử lại sau.',
                            );
                          }
                          final charts = _sortCharts(snapshot.data ?? []);
                          final pointsCount = charts.fold<int>(
                            0,
                            (s, c) => s + c.points.length,
                          );
                          if (charts.isEmpty) {
                            return _EmptyState(rangeLabel: _selectedRange);
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  _SectionLabel(
                                    icon: Icons.bar_chart_rounded,
                                    iconColor: AppColors.textSecondary,
                                    label: 'Biểu đồ',
                                  ),
                                  const Spacer(),
                                  Flexible(
                                    child: Text(
                                      '$pointsCount lần ghi · $_selectedRange',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textGrey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: charts.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) =>
                                    StatsChartCard(
                                  chart: charts[index],
                                  selectedRange: _rangeParam(_selectedRange),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _SectionLabel({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData? icon;
  const _Chip({
    required this.label,
    required this.color,
    required this.bgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? time;
  const _LiveChip({required this.label, this.value, this.time});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasValue
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 14,
            color: hasValue ? AppColors.primary : AppColors.textGrey,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                hasValue ? value! : '—',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: hasValue ? AppColors.primary : AppColors.textLight,
                ),
              ),
              if (time != null)
                Text(
                  time!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

class _EmptyState extends StatelessWidget {
  final String rangeLabel;
  final String? errorMessage;
  const _EmptyState({required this.rangeLabel, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            errorMessage != null
                ? Icons.cloud_off_outlined
                : Icons.bar_chart_rounded,
            size: 48,
            color: AppColors.textGrey,
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Không có dữ liệu trong $rangeLabel',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage != null
                ? 'Kiểm tra kết nối hoặc thử lại.'
                : 'Thử đổi bộ lọc để xem dữ liệu khác.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
