import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/medication/medication_share.dart';
import 'package:fe/data/repositories/family_repository.dart';
import 'package:fe/data/repositories/medication_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicationShareDialog extends StatefulWidget {
  final Medication medication;

  const MedicationShareDialog({
    super.key,
    required this.medication,
  });

  @override
  State<MedicationShareDialog> createState() => _MedicationShareDialogState();
}

class _MedicationShareDialogState extends State<MedicationShareDialog> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final Map<String, _GroupShareOption> _groupsById = {};
  final Set<String> _selectedKeys = {};
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
      _groupsById.clear();
      _selectedKeys.clear();
      _existingSharesByKey.clear();
    });

    try {
      final familyRepo = context.read<FamilyRepository>();
      final medicationRepo = context.read<MedicationRepository>();

      final summary = await familyRepo.getFamilyGroups();
      final shares = await medicationRepo.getMedicationShares(widget.medication.id);

      for (final share in shares) {
        _existingSharesByKey[_shareKey(share.groupId, share.sharedWithUserId)] =
            share;
      }

      for (final group in summary.groups) {
        if (!group.medicationSharingAllowed) continue;
        final details = await familyRepo.getGroupDetails(
          groupId: group.id,
          cachedGroup: group,
        );
        final eligibleMembers = details.members
            .where((member) =>
                member.userId != widget.medication.userId &&
                member.sharedMetrics.isNotEmpty)
            .toList();

        if (eligibleMembers.isEmpty) continue;

        _groupsById[group.id] = _GroupShareOption(
          group: details.group,
          members: eligibleMembers,
        );
      }

      for (final entry in _groupsById.entries) {
        final groupId = entry.key;
        for (final member in entry.value.members) {
          final key = _shareKey(groupId, member.userId);
          if (_existingSharesByKey.containsKey(key)) {
            _selectedKeys.add(key);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được danh sách thành viên có thể chia sẻ thuốc.';
      });
    }
  }

  String _shareKey(String groupId, String userId) => '$groupId|$userId';

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final medicationRepo = context.read<MedicationRepository>();
      final desiredKeys = Set<String>.from(_selectedKeys);
      final existingKeys = _existingSharesByKey.keys.toSet();

      final keysToAdd = desiredKeys.difference(existingKeys);
      final keysToDelete = existingKeys.difference(desiredKeys);

      for (final key in keysToAdd) {
        final parts = key.split('|');
        if (parts.length != 2) continue;
        await medicationRepo.addMedicationShare(
          medicationId: widget.medication.id,
          groupId: parts[0],
          sharedWithUserId: parts[1],
        );
      }

      for (final key in keysToDelete) {
        final existing = _existingSharesByKey[key];
        if (existing == null) continue;
        await medicationRepo.deleteMedicationShare(
          medicationId: widget.medication.id,
          shareId: existing.id,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu chia sẻ thuốc. Vui lòng thử lại.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chia sẻ nhắc thuốc',
                      style: AppTextStyles.h4.copyWith(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Thuốc: ${widget.medication.name}. Chỉ hiện thành viên thuộc nhóm đã bật chia sẻ nhắc thuốc và đang chia sẻ ít nhất một chỉ số với bạn.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _buildBody(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: (_loading || _saving) ? null : _save,
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

  Widget _buildBody() {
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

    if (_groupsById.isEmpty) {
      return Center(
        child: Text(
          'Không có thành viên nào đủ quyền để chia sẻ nhắc thuốc.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final groups = _groupsById.values.toList()
      ..sort((a, b) => a.group.name.compareTo(b.group.name));

    return ListView.separated(
      shrinkWrap: true,
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = groups[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: ExpansionTile(
            title: Text(
              group.group.name,
              style: AppTextStyles.labelMedium,
            ),
            subtitle: Text(
              '${group.members.length} thành viên có thể nhận nhắc thuốc',
              style: AppTextStyles.caption,
            ),
            children: group.members.map((member) {
              final key = _shareKey(group.group.id, member.userId);
              final selected = _selectedKeys.contains(key);
              return CheckboxListTile(
                value: selected,
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
                            _selectedKeys.add(key);
                          } else {
                            _selectedKeys.remove(key);
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

class _GroupShareOption {
  final FamilyGroup group;
  final List<FamilyMember> members;

  const _GroupShareOption({
    required this.group,
    required this.members,
  });
}
