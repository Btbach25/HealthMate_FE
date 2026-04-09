import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/presentation/medications/bloc/medication_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Danh sách thuốc đang lưu — cho phép xóa khỏi lịch (DB).
class ManageMedicationsDialog extends StatelessWidget {
  const ManageMedicationsDialog({super.key});

  Future<void> _confirmDelete(BuildContext context, Medication med) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thuốc?'),
        content: Text(
          'Xóa “${med.name}” và toàn bộ nhắc giờ liên quan? '
          'Thao tác này không thể hoàn tác.',
          style: AppTextStyles.bodySmall.copyWith(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final bloc = context.read<MedicationBloc>();
      if (bloc.state.deletingMedicationId != null) return;
      bloc.add(DeleteMedication(medicationId: med.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.72;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 420,
        height: maxH.clamp(280.0, 520.0),
        child: BlocBuilder<MedicationBloc, MedicationState>(
          builder: (context, state) {
            final meds = state.medications;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chỉnh sửa lịch thuốc',
                          style: AppTextStyles.h4.copyWith(fontSize: 18),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Đóng',
                      ),
                    ],
                  ),
                  Text(
                    'Xóa thuốc khi đổi đơn hoặc không còn dùng.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: meds.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Chưa có thuốc nào.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: meds.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final med = meds[index];
                              final deleting =
                                  state.deletingMedicationId == med.id;
                              final busy = state.deletingMedicationId != null;
                              final times = med.reminders
                                  .map((r) => r.time)
                                  .join(', ');
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                title: Text(
                                  med.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    [
                                      med.dosage,
                                      if (times.isNotEmpty) 'Nhắc: $times',
                                    ].join(' · '),
                                    style: AppTextStyles.caption,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: deleting
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.error,
                                        ),
                                        tooltip: 'Xóa khỏi lịch',
                                        onPressed: busy
                                            ? null
                                            : () =>
                                                _confirmDelete(context, med),
                                      ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

