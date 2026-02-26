import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fe/presentation/home/bloc/health_overview_bloc.dart';
import 'package:fe/data/models/health/health_overview.dart';
import '../../../core/theme/app_colors.dart';

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
              message: state.errorMessage ?? 'Lỗi lấy dữ liệu',
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
    return Card(
      color: AppColors.tagUrgentBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.tagUrgentText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: AppColors.tagUrgentText, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final HealthOverview overview;
  const _DataCard({required this.overview});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tình trạng sức khỏe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _metricRow('Nhịp tim', overview.heartRate?.value, 'bpm'),
            _metricRow('Cân nặng', overview.weight?.value, 'kg'),
            _metricRow('Huyết áp', _bpValue(overview), ''),
            _metricRow('Nhiệt độ', overview.temperature?.value, '°C'),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, Object? value, String unit) {
    final display = value == null || (value is String && value.isEmpty)
        ? '—'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(unit.isNotEmpty ? '$display $unit' : display, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _bpValue(HealthOverview o) {
    final bp = o.bloodPressure;
    if (bp == null) return '—';
    return '${bp.systolic}/${bp.diastolic}';
  }
}
