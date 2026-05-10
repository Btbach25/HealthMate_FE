import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/home/bloc/health_overview_bloc.dart';
import 'package:fe/data/models/health/health_overview.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';

class HealthOverviewSection extends StatefulWidget {
  const HealthOverviewSection({super.key});

  @override
  State<HealthOverviewSection> createState() => _HealthOverviewSectionState();
}

class _HealthOverviewSectionState extends State<HealthOverviewSection> {
  @override
  void initState() {
    super.initState();
    // Delay to ensure bloc is available in widget tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthOverviewBloc>().add(const HealthOverviewRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HealthOverviewBloc, HealthOverviewState>(
      builder: (context, state) {
        switch (state.status) {
          case HealthOverviewStatus.initial:
          case HealthOverviewStatus.loading:
            return const _LoadingCard();
          case HealthOverviewStatus.failure:
            return _ErrorCard(
              message: state.errorMessage ?? 'Không tải được chỉ số sức khỏe. Kiểm tra kết nối và thử lại.',
              onRetry: () => context.read<HealthOverviewBloc>().add(const HealthOverviewRetried()),
            );
          case HealthOverviewStatus.success:
            return _DataCard(overview: state.overview ?? HealthOverview.empty());
        }
      },
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(height: 24, width: 24, child: CircularProgressIndicator()),
            SizedBox(width: 12),
            Text('Đang tải tình trạng sức khỏe...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cloud_off_outlined, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Thử lại', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final HealthOverview overview;
  const _DataCard({required this.overview});

  String _fmt(Object? value) =>
      (value == null || (value is String && value.isEmpty)) ? '—' : value.toString();

  String _bpValue(HealthOverview o) {
    final bp = o.bloodPressure;
    if (bp == null) return '—';
    return '${bp.systolic}/${bp.diastolic}';
  }

  @override
  Widget build(BuildContext context) {
    // BE overview may not carry weight — fall back to profile weight from AuthBloc.
    final profileWeight = context.select((AuthBloc b) => b.state.user.weight);
    final weightValue = overview.weight?.value ?? profileWeight;

    final metrics = [
      _MetricItem(
        icon: AppIcons.heart,
        iconColor: AppColors.heartIconColor,
        iconBgColor: AppColors.heartIconBg,
        label: 'Nhịp tim',
        value: _fmt(overview.heartRate?.value),
        unit: 'bpm',
      ),
      _MetricItem(
        icon: AppIcons.weight,
        iconColor: AppColors.weightIconColor,
        iconBgColor: AppColors.weightIconBg,
        label: 'Cân nặng',
        value: _fmt(weightValue),
        unit: 'kg',
      ),
      _MetricItem(
        icon: AppIcons.bloodPressure,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryContainer,
        label: 'Huyết áp',
        value: _bpValue(overview),
        unit: 'mmHg',
      ),
      _MetricItem(
        icon: AppIcons.temperature,
        iconColor: AppColors.tempIconColor,
        iconBgColor: AppColors.tempIconBg,
        label: 'Nhiệt độ',
        value: _fmt(overview.temperature?.value),
        unit: '°C',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.monitor_heart_outlined, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tình trạng sức khỏe',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textBlack),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MetricTile(item: metrics[0])),
              const SizedBox(width: 10),
              Expanded(child: _MetricTile(item: metrics[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MetricTile(item: metrics[2])),
              const SizedBox(width: 10),
              Expanded(child: _MetricTile(item: metrics[3])),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;
  final String unit;
  const _MetricItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.unit,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricItem item;
  const _MetricTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isEmpty = item.value == '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isEmpty ? '—' : item.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isEmpty ? AppColors.textLight : AppColors.textBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isEmpty && item.unit.isNotEmpty)
                  Text(
                    item.unit,
                    style: const TextStyle(fontSize: 10, color: AppColors.textGrey, height: 1.1),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
