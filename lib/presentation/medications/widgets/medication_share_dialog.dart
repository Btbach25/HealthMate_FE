import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/repositories/family_repository.dart';
import 'package:fe/data/repositories/medication_repository.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Chia sẻ lịch nhắc thuốc cho thành viên trong nhóm gia đình.
///
/// Hai bước trong cùng một dialog: chọn nhóm → chọn thành viên → xác nhận.
///
/// Bắt buộc [medications] (chia sẻ CẢ danh sách, không chọn lẻ từng thuốc) và
/// phải khác rỗng — phía gọi đã chặn sẵn khi chưa có thuốc nào.
/// PHỤ THUỘC context: [FamilyRepository], [MedicationRepository] và [AuthBloc].
/// Khác các dialog cùng thư mục, nó KHÔNG cần [MedicationBloc] vì gọi thẳng
/// repository và không đổi lịch của chính người dùng.
///
/// Chỉ liệt kê thành viên khác mình và có bật chia sẻ chỉ số. Việc gửi là
/// vòng lặp `số thuốc × số người` gọi API lần lượt: không có transaction, lỗi
/// giữa chừng thì phần trước đó đã chia sẻ xong.
class MedicationShareDialog extends StatefulWidget {
  final List<Medication> medications;

  const MedicationShareDialog({
    super.key,
    required this.medications,
  });

  @override
  State<MedicationShareDialog> createState() => _MedicationShareDialogState();
}

class _MedicationShareDialogState extends State<MedicationShareDialog> {
  // --- Bước 1: chọn nhóm ---
  bool _loadingGroups = true;
  List<FamilyGroup> _groups = [];
  String? _loadError;

  // --- Bước 2: chọn thành viên (null = đang ở bước 1) ---
  FamilyGroup? _selectedGroup;
  List<FamilyMember> _groupMembers = [];
  bool _loadingMembers = false;
  final Set<String> _selectedUserIds = {};

  // --- Đang gửi: khoá mọi nút, kể cả nút đóng ---
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loadingGroups = true;
      _loadError = null;
    });
    try {
      final familyRepo = context.read<FamilyRepository>();
      final summary = await familyRepo.getFamilyGroups();
      final eligible = summary.groups.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _groups = eligible;
        _loadingGroups = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingGroups = false;
        _loadError = 'Không tải được danh sách nhóm.';
      });
    }
  }

  /// Sang bước 2 và nạp thành viên của nhóm.
  ///
  /// Chỉ giữ người khác mình VÀ đã bật chia sẻ chỉ số — người chưa bật thì gửi
  /// nhắc thuốc sang cũng không hiển thị được.
  Future<void> _selectGroup(FamilyGroup group) async {
    setState(() {
      _selectedGroup = group;
      _loadingMembers = true;
      _selectedUserIds.clear();
      _groupMembers = [];
    });
    try {
      final familyRepo = context.read<FamilyRepository>();
      final details = await familyRepo.getGroupDetails(
        groupId: group.id,
        cachedGroup: group,
      );
      if (!mounted) return;
      final currentUserId = context.read<AuthBloc>().state.user.id;
      final eligible = details.members
          .where((m) => m.userId != currentUserId && m.sharedMetrics.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _groupMembers = eligible;
        _loadingMembers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMembers = false;
        _groupMembers = [];
      });
    }
  }

  void _backToGroups() {
    setState(() {
      _selectedGroup = null;
      _groupMembers = [];
      _selectedUserIds.clear();
    });
  }

  /// Hỏi xác nhận rồi gửi lần lượt `số thuốc × số người` lời mời chia sẻ.
  ///
  /// Không có transaction: lỗi giữa chừng thì phần đã gửi vẫn có hiệu lực,
  /// người dùng chỉ thấy một thông báo lỗi chung.
  Future<void> _onConfirm() async {
    if (_selectedUserIds.isEmpty || _sharing) return;
    final group = _selectedGroup!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: const Text(
          'Xác nhận chia sẻ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Chia sẻ toàn bộ ${widget.medications.length} loại thuốc '
          'cho ${_selectedUserIds.length} thành viên trong nhóm "${group.name}"?',
          style: AppTextStyles.bodySmall.copyWith(
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textGrey,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Chia sẻ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sharing = true);

    bool success = true;
    try {
      final medicationRepo = context.read<MedicationRepository>();
      for (final med in widget.medications) {
        for (final userId in _selectedUserIds) {
          await medicationRepo.addMedicationShare(
            medicationId: med.id,
            groupId: group.id,
            sharedWithUserId: userId,
          );
        }
      }
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã chia sẻ nhắc thuốc thành công'
              : 'Không thể chia sẻ nhắc thuốc. Vui lòng thử lại.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppColors.primary : AppColors.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );

    setState(() => _sharing = false);
    _backToGroups();
  }

  @override
  Widget build(BuildContext context) {
    final onGroupsScreen = _selectedGroup == null;
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
                  if (!onGroupsScreen) ...[
                    IconButton(
                      onPressed: _sharing ? null : _backToGroups,
                      icon: const Icon(Icons.arrow_back_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      onGroupsScreen
                          ? 'Chia sẻ nhắc thuốc'
                          : _selectedGroup!.name,
                      style: AppTextStyles.h4.copyWith(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: _sharing ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                onGroupsScreen
                    ? 'Chia sẻ toàn bộ ${widget.medications.length} loại thuốc'
                    : 'Chọn thành viên muốn chia sẻ nhắc thuốc',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: onGroupsScreen ? _buildGroupsList() : _buildMembersList(),
              ),
              if (!onGroupsScreen) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed:
                      (_selectedUserIds.isEmpty || _sharing || _loadingMembers)
                          ? null
                          : _onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Xác nhận (${_selectedUserIds.length} thành viên)',
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList() {
    if (_loadingGroups) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadGroups,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Không có nhóm nào cho phép chia sẻ nhắc thuốc.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.8,
        color: AppColors.cardBorder,
      ),
      itemBuilder: (context, index) {
        final group = _groups[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            group.name,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${group.memberCount} thành viên',
            style: AppTextStyles.caption,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: AppColors.primary),
            tooltip: 'Chia sẻ vào nhóm này',
            onPressed: () => _selectGroup(group),
          ),
        );
      },
    );
  }

  Widget _buildMembersList() {
    if (_loadingMembers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_groupMembers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Không có thành viên nào có thể nhận nhắc thuốc trong nhóm này.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _groupMembers.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.8,
        color: AppColors.cardBorder,
      ),
      itemBuilder: (context, index) {
        final member = _groupMembers[index];
        final selected = _selectedUserIds.contains(member.userId);
        return CheckboxListTile(
          value: selected,
          activeColor: AppColors.primary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          title: Text(
            member.name,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: member.email != null
              ? Text(member.email!, style: AppTextStyles.caption)
              : null,
          onChanged: _sharing
              ? null
              : (value) {
                  setState(() {
                    if (value == true) {
                      _selectedUserIds.add(member.userId);
                    } else {
                      _selectedUserIds.remove(member.userId);
                    }
                  });
                },
        );
      },
    );
  }
}
