import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/string_helper.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Modal chuyển quyền chủ nhóm. Chỉ chủ nhóm mở được, và chỉ tự động bật lên khi
/// chủ nhóm bấm "Rời nhóm" trong lúc nhóm vẫn còn thành viên khác — nhóm không
/// được phép tồn tại mà không có chủ.
///
/// [members] đã lọc bỏ chính người dùng hiện tại. Bắn [TransferOwnership]; khi
/// `ownershipTransferred` về thì modal tự đóng và hỏi tiếp có rời nhóm luôn không.
/// Không trả về giá trị; việc điều hướng sau khi rời do `GroupDetailsView` lo.
class TransferOwnershipModal extends StatefulWidget {
  final String groupId;
  final List<FamilyMember> members;

  const TransferOwnershipModal({
    super.key,
    required this.groupId,
    required this.members,
  });

  @override
  State<TransferOwnershipModal> createState() => _TransferOwnershipModalState();
}

class _TransferOwnershipModalState extends State<TransferOwnershipModal> {
  String? _selectedMemberId;

  /// Gửi yêu cầu chuyển quyền (PUT /groups/:id/owner, body `new_owner_id`).
  /// `newOwnerId` lấy từ `member.id`, hiện luôn bằng `member.userId` vì
  /// `GroupApiMapper.toFamilyMember` gán `id = userId`.
  void _handleTransfer() {
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn chủ nhóm mới'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final bloc = context.read<FamilyBloc>();
    bloc.add(
          TransferOwnership(
            groupId: widget.groupId,
            newOwnerId: _selectedMemberId!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state.status == FamilyStatus.ownershipTransferred) {
          if (!context.mounted) return;
          final bloc = context.read<FamilyBloc>();
          final rootNav = Navigator.of(context, rootNavigator: true);
          // Đóng modal chuyển quyền (route trên root navigator)
          rootNav.pop();
          // Mở dialog xác nhận rời nhóm bằng root context ổn định
          _showLeaveConfirmationAfterTransfer(rootNav.context, bloc, widget.groupId);
        }
        if (state.status == FamilyStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Có lỗi xảy ra'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(AppSize.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chuyển quyền chủ nhóm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.textGrey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bạn cần chuyển quyền chủ nhóm cho thành viên khác trước khi rời nhóm',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Chọn chủ nhóm mới',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 16),
              ...widget.members.map((member) {
                final isSelected = _selectedMemberId == member.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMemberId = member.id;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSize.p16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                StringHelper.getInitials(member.name),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
                                Text(
                                  member.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textBlack,
                                  ),
                                ),
                                if (member.relationship != null)
                                  Text(
                                    member.relationship!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textGrey.withValues(alpha: 0.8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textGrey.withValues(alpha: 0.5),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textBlack,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _handleTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Xác nhận và rời nhóm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sau khi chuyển quyền xong, hiện dialog xác nhận rời nhóm.
  /// Navigation khi rời nhóm thành công sẽ do GroupDetailsView BlocListener xử lý.
  void _showLeaveConfirmationAfterTransfer(
    BuildContext rootContext,
    FamilyBloc bloc,
    String groupId,
  ) {
    showDialog(
      context: rootContext,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rời nhóm'),
        content: const Text(
          'Bạn đã chuyển quyền chủ nhóm thành công. Bạn có muốn rời nhóm này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Ở lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(LeaveGroup(groupId: groupId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Xác nhận rời nhóm'),
          ),
        ],
      ),
    );
  }
}
