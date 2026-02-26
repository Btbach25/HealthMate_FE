import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/string_helper.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    context.read<FamilyBloc>().add(
          TransferOwnership(
            groupId: widget.groupId,
            newOwnerId: _selectedMemberId!,
          ),
        );
  }

  void _showLeaveConfirmationAfterTransfer(BuildContext context, String groupId) {
    showDialog(
      context: context,
      builder: (context) => BlocListener<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state.status == FamilyStatus.groupLeft) {
            // Navigate back to family page
            if (context.mounted) {
              Navigator.pop(context); // Close confirmation dialog
              // Pop back to family page (group_details_view will also pop)
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã chuyển quyền chủ nhóm và rời nhóm thành công'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              });
            }
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
        child: AlertDialog(
          title: const Text('Rời nhóm'),
          content: const Text(
            'Bạn đã chuyển quyền chủ nhóm thành công. Bạn có chắc chắn muốn rời nhóm này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog first
                context.read<FamilyBloc>().add(
                      LeaveGroup(groupId: groupId),
                    );
                // Navigation will be handled by BlocListener
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Xác nhận rời nhóm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state.status == FamilyStatus.ownershipTransferred) {
          // After transferring ownership, show confirmation dialog to leave group
          if (context.mounted) {
            Navigator.pop(context); // Close transfer modal first
            _showLeaveConfirmationAfterTransfer(context, widget.groupId);
          }
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
                  color: Colors.orange.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha:0.3),
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
                            ? AppColors.primary.withValues(alpha:0.1)
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
                                      color: AppColors.textGrey.withValues(alpha:0.8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 24,
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked,
                              color: AppColors.textGrey.withValues(alpha:0.5),
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
}

