import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/user_id_utils.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/medication/medication_share.dart';
import 'package:fe/data/repositories/medication_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dialog cấu hình chia sẻ nhắc uống thuốc theo **từng loại thuốc × từng thành viên**.
/// Mở từ nút "Quản lý tại đây" ở màn chi tiết nhóm, và nút đó chỉ bật khi nhóm đã
/// cho phép chia sẻ nhắc thuốc (`group.medicationSharingAllowed`).
///
/// Chỉ liệt kê thành viên vừa khác chính mình vừa có `medicationReminderShareAllowed`
/// — tức đã qua cả hai tầng quyền (cài đặt nhóm và quyền riêng từng người).
///
/// Không đi qua [FamilyBloc]: gọi thẳng `MedicationRepository`, so sánh trạng thái
/// đã chọn với các bản ghi chia sẻ hiện có rồi thêm/xoá phần chênh lệch.
/// Trả về `true` qua `Navigator.pop` khi lưu thành công.
class GroupMedicationShareDialog extends StatefulWidget {
  final String groupId;
  final List<FamilyMember> members;
  final String currentUserId;

  const GroupMedicationShareDialog({
    super.key,
    required this.groupId,
    required this.members,
    required this.currentUserId,
  });

  @override
  State<GroupMedicationShareDialog> createState() =>
      _GroupMedicationShareDialogState();
}

class _GroupMedicationShareDialogState
    extends State<GroupMedicationShareDialog> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<Medication> _medications = const [];
  final Map<String, Set<String>> _selectedByMedication = {};
  final Map<String, MedicationShare> _existingSharesByKey = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _medications = const [];
      _selectedByMedication.clear();
      _existingSharesByKey.clear();
    });

    try {
      final repo = context.read<MedicationRepository>();
      final meds = await repo.getMedications();
      _medications = meds;

      for (final med in meds) {
        final shares = await repo.getMedicationShares(med.id);
        final selected = <String>{};
        for (final share in shares) {
          if (share.groupId != widget.groupId) continue;
          final key = _shareKey(share.medicationId, share.sharedWithUserId);
          _existingSharesByKey[key] = share;
          selected.add(share.sharedWithUserId);
        }
        _selectedByMedication[med.id] = selected;
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được dữ liệu chia sẻ thuốc của nhóm.';
      });
    }
  }

  String _shareKey(String medicationId, String userId) =>
      '$medicationId|$userId';

  /// Lưu theo kiểu so sánh chênh lệch: với mỗi thuốc, thêm những người mới tick và
  /// xoá bản ghi của những người vừa bỏ tick. Không có API ghi đè hàng loạt.
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final repo = context.read<MedicationRepository>();
      for (final med in _medications) {
        final medicationId = med.id;
        final selected = _selectedByMedication[medicationId] ?? <String>{};
        final existingUserIds = _existingSharesByKey.values
            .where(
              (s) =>
                  s.medicationId == medicationId && s.groupId == widget.groupId,
            )
            .map((s) => s.sharedWithUserId)
            .toSet();

        final toAdd = selected.difference(existingUserIds);
        final toDelete = existingUserIds.difference(selected);

        for (final userId in toAdd) {
          await repo.addMedicationShare(
            medicationId: medicationId,
            groupId: widget.groupId,
            sharedWithUserId: userId,
          );
        }
        for (final userId in toDelete) {
          final share = _existingSharesByKey[_shareKey(medicationId, userId)];
          if (share == null) continue;
          await repo.deleteMedicationShare(
            medicationId: medicationId,
            shareId: share.id,
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu chia sẻ thất bại. Vui lòng thử lại.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligibleMembers = widget.members
        .where(
          (m) =>
              !sameUserId(m.userId, widget.currentUserId) &&
              m.medicationReminderShareAllowed,
        )
        .toList();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chia sẻ nhắc uống thuốc trong nhóm',
                      style: AppTextStyles.h4,
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Thiết lập theo từng thuốc. Chỉ hiện thành viên mà nhóm cho phép nhận nhắc thuốc.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _buildBody(eligibleMembers),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: (_loading || _saving || eligibleMembers.isEmpty)
                    ? null
                    : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu chia sẻ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<FamilyMember> eligibleMembers) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_medications.isEmpty) {
      return Center(
        child: Text(
          'Chưa có thuốc để cấu hình chia sẻ.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
        ),
      );
    }
    if (eligibleMembers.isEmpty) {
      return Center(
        child: Text(
          'Không có thành viên nào đủ quyền để nhận nhắc thuốc.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _medications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final med = _medications[index];
        final selected = _selectedByMedication.putIfAbsent(
          med.id,
          () => <String>{},
        );
        return Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: ExpansionTile(
            title: Text(med.name, style: AppTextStyles.labelMedium),
            subtitle: Text(
              med.dosage,
              style: AppTextStyles.caption,
            ),
            children: eligibleMembers.map((member) {
              final checked = selected.contains(member.userId);
              return CheckboxListTile(
                value: checked,
                activeColor: AppColors.primary,
                title: Text(member.name, style: AppTextStyles.bodySmall),
                subtitle: Text(
                  member.email ?? member.userId,
                  style: AppTextStyles.caption,
                ),
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          if (value == true) {
                            selected.add(member.userId);
                          } else {
                            selected.remove(member.userId);
                          }
                        });
                      },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
