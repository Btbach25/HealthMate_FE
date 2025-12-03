import 'dart:async';

import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddMemberModal extends StatefulWidget {
  final String groupId;

  const AddMemberModal({super.key, required this.groupId});

  @override
  State<AddMemberModal> createState() => _AddMemberModalState();
}

class _AddMemberModalState extends State<AddMemberModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedRelationship;
  final Set<MetricOption> _selectedMetrics = {};
  String? _inlineMessage;
  Color? _inlineMessageColor;
  Timer? _messageTimer;
  bool _isLoading = false;

  final List<String> _relationships = [
    'Bố',
    'Mẹ',
    'Con trai',
    'Con gái',
    'Anh',
    'Chị',
    'Em trai',
    'Em gái',
    'Ông',
    'Bà',
    'Khác',
  ];

  final List<MetricOption> _availableMetrics = [
    MetricOption(
      type: MetricType.heartRate,
      label: 'Nhịp tim',
      icon: AppIcons.heart,
    ),
    MetricOption(
      type: MetricType.bloodPressure,
      label: 'Huyết áp',
      icon: AppIcons.bloodPressure,
    ),
    MetricOption(
      type: MetricType.weight,
      label: 'Cân nặng',
      icon: AppIcons.weight,
    ),
    MetricOption(
      type: MetricType.temperature,
      label: 'Nhiệt độ',
      icon: AppIcons.temperature,
    ),
    MetricOption(
      type: MetricType.sleep,
      label: 'Giấc ngủ',
      icon: AppIcons.sleep,
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _handleInvite() {
    if (_isLoading) return;
    
    if (!_formKey.currentState!.validate()) {
      _showInlineMessage('Vui lòng điền đầy đủ thông tin');
      return;
    }

    if (_selectedMetrics.isEmpty) {
      _showInlineMessage('Vui lòng chọn ít nhất một loại dữ liệu chia sẻ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    context.read<FamilyBloc>().add(
          InviteMember(
            groupId: widget.groupId,
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
            relationship: _selectedRelationship,
            age: null,
            sharedMetrics: _selectedMetrics.map((m) => m.type.value).toList(),
          ),
        );
  }

  void _showInlineMessage(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 5),
  }) {
    _messageTimer?.cancel();
    setState(() {
      _inlineMessage = message;
      _inlineMessageColor =
          backgroundColor ?? Colors.black.withOpacity(0.85);
    });
    _messageTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _inlineMessage = null;
        });
      }
    });
  }

  // Parse error message để hiển thị tiếng Việt thân thiện hơn
  String _parseErrorMessage(String? errorMessage) {
    if (errorMessage == null) {
      return 'Có lỗi xảy ra. Vui lòng thử lại sau.';
    }
    
    // Chuyển đổi các error messages phổ biến sang tiếng Việt
    final lowerError = errorMessage.toLowerCase();
    
    if (lowerError.contains('group not found')) {
      return 'Không tìm thấy nhóm. Vui lòng thử lại.';
    }
    if (lowerError.contains('email') && lowerError.contains('already')) {
      return 'Email này đã được mời vào nhóm.';
    }
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.';
    }
    if (lowerError.contains('permission') || lowerError.contains('unauthorized')) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }
    if (lowerError.contains('timeout')) {
      return 'Yêu cầu quá thời gian chờ. Vui lòng thử lại.';
    }
    
    // Nếu không match với các pattern trên, trả về message gốc hoặc message mặc định
    return errorMessage.contains('Exception:') 
        ? 'Có lỗi xảy ra. Vui lòng thử lại sau.'
        : errorMessage;
  }

  Widget _buildDialogContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSize.p24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thêm thành viên mới',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Điền thông tin và chọn dữ liệu chia sẻ để mời thành viên vào nhóm',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(height: AppSize.spacing24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Họ tên',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập họ tên',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Nhập email để gửi lời mời',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    final emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
                    final regex = RegExp(emailPattern);
                    if (!regex.hasMatch(value.trim())) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mối quan hệ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedRelationship,
                  decoration: const InputDecoration(
                    hintText: 'Chọn mối quan hệ',
                  ),
                  items: _relationships.map((rel) {
                    return DropdownMenuItem(
                      value: rel,
                      child: Text(rel),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRelationship = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dữ liệu chia sẻ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn loại dữ liệu sức khỏe mà thành viên này có thể xem',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableMetrics.map((metric) {
                    final isSelected =
                        _selectedMetrics.any((m) => m.type == metric.type);
                    return SizedBox(
                      width: 180,
                      child: _MetricCheckbox(
                        metric: metric,
                        isSelected: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedMetrics.add(metric);
                            } else {
                              _selectedMetrics
                                  .removeWhere((m) => m.type == metric.type);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_inlineMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSize.p16,
                vertical: AppSize.p12,
              ),
              decoration: BoxDecoration(
                color: _inlineMessageColor ?? Colors.black87,
                borderRadius: BorderRadius.circular(AppSize.r12),
              ),
              child: Text(
                _inlineMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Gửi lời mời',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state.status == FamilyStatus.memberInvited) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pop(context);
          // Hiển thị thông báo thành công
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi lời mời thành công'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 3),
            ),
          );
        }
        if (state.status == FamilyStatus.error) {
          setState(() {
            _isLoading = false;
          });
          // Parse và hiển thị error message tiếng Việt
          final errorMsg = _parseErrorMessage(state.errorMessage);
          _showInlineMessage(
            errorMsg,
            backgroundColor: AppColors.error,
          );
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSize.r24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Luôn cho phép cuộn dọc nếu nội dung cao hơn khung,
                  // trên màn hình cao thì hầu như không cần cuộn.
                  return SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    child: _buildDialogContent(context),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MetricOption {
  final MetricType type;
  final String label;
  final IconData icon;

  MetricOption({
    required this.type,
    required this.label,
    required this.icon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetricOption &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;
}

class _MetricCheckbox extends StatelessWidget {
  final MetricOption metric;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _MetricCheckbox({
    required this.metric,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: const EdgeInsets.all(AppSize.p16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSize.r12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) => onChanged(value ?? false),
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                metric.icon,
                color: isSelected
                    ? Colors.white
                    : AppColors.textGrey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                metric.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: AppColors.textBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

