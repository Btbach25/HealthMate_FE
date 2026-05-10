import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../bloc/device_health_cubit.dart';

class DeviceActivityCard extends StatelessWidget {
  const DeviceActivityCard({super.key});

  static const int _stepGoal = 10000;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceHealthCubit, DeviceHealthState>(
      builder: (context, state) {
        if (state.loading) return const _ActivityLoading();
        if (state.lastUpdated == null) return const SizedBox.shrink();
        return _ActivityContent(state: state);
      },
    );
  }
}

class _ActivityLoading extends StatelessWidget {
  const _ActivityLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Row(
        children: const [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Đang đồng bộ thiết bị...', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

class _ActivityContent extends StatelessWidget {
  final DeviceHealthState state;
  const _ActivityContent({required this.state});

  String _syncLabel() {
    final ts = state.lastUpdated;
    if (ts == null) return '';
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Vừa cập nhật';
    if (diff.inMinutes < 60) return 'Cập nhật ${diff.inMinutes} phút trước';
    return 'Cập nhật ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final steps = state.totalSteps;
    final percent = steps != null
        ? (steps / DeviceActivityCard._stepGoal).clamp(0.0, 1.0)
        : 0.0;
    final reached = steps != null && steps >= DeviceActivityCard._stepGoal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
                  color: reached ? AppColors.successLight : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppIcons.steps,
                  color: reached ? AppColors.success : AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Hoạt động hôm nay',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textBlack),
              ),
              const Spacer(),
              Text(
                _syncLabel(),
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                steps != null ? steps.toString() : '—',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: reached ? AppColors.success : AppColors.textBlack,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'bước',
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              Text(
                'Mục tiêu: ${DeviceActivityCard._stepGoal ~/ 1000}k',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.inputBackground,
              color: reached ? AppColors.success : AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.devices_outlined, size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                '${state.dataCount} chỉ số từ thiết bị',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
              if (reached) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Đạt mục tiêu! 🎉',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
