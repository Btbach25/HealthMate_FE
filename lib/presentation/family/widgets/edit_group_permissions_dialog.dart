import 'dart:async';

import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MetricOption {
  final MetricType type;
  final String label;
  final IconData icon;

  MetricOption({
    required this.type,
    required this.label,
    required this.icon,
  });
}

class EditGroupPermissionsDialog extends StatefulWidget {
  final FamilyGroup group;

  const EditGroupPermissionsDialog({
    super.key,
    required this.group,
  });

  @override
  State<EditGroupPermissionsDialog> createState() =>
      _EditGroupPermissionsDialogState();
}

class _EditGroupPermissionsDialogState
    extends State<EditGroupPermissionsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<MetricOption> _selectedMetrics = {};
  String? _inlineMessage;
  Color? _inlineMessageColor;
  Timer? _messageTimer;
  bool _isLoading = false;
  
  static const int _maxGroupNameLength = 50;

  final List<MetricOption> _availableMetrics = [
    MetricOption(
      type: MetricType.heartRate,
      label: 'Nhịp tim',
      icon: AppIcons.heart,
    ),
    MetricOption(
      type: MetricType.stepsCount,
      label: 'Số bước chân',
      icon: AppIcons.steps,
    ),
    MetricOption(
      type: MetricType.caloriesBurnt,
      label: 'Lượng calo',
      icon: Icons.local_fire_department_outlined,
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
      type: MetricType.sleep,
      label: 'Giấc ngủ',
      icon: AppIcons.sleep,
    ),
    MetricOption(
      type: MetricType.temperature,
      label: 'Nhiệt độ cơ thể',
      icon: AppIcons.temperature,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Set current group name
    _nameController.text = widget.group.name;
    // Pre-select current group metrics
    for (final metric in widget.group.sharedMetrics) {
      final option = _availableMetrics.firstWhere(
        (m) => m.type == metric,
        orElse: () => _availableMetrics.first,
      );
      _selectedMetrics.add(option);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _handleSave() {
    if (_isLoading) return;

    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showInlineMessage(
        'Vui lòng kiểm tra lại thông tin',
        backgroundColor: AppColors.error,
      );
      return;
    }

    if (_selectedMetrics.isEmpty) {
      _showInlineMessage(
        'Vui lòng chọn ít nhất một chỉ số để chia sẻ',
        backgroundColor: AppColors.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newName = _nameController.text.trim();
    final nameChanged = newName != widget.group.name;
    final metricsChanged = !_areMetricsEqual(_selectedMetrics, widget.group.sharedMetrics);

    // Only update if something changed
    if (nameChanged || metricsChanged) {
      context.read<FamilyBloc>().add(
            UpdateGroup(
              groupId: widget.group.id,
              name: nameChanged ? newName : null,
              sharedMetrics: metricsChanged
                  ? _selectedMetrics.map((m) => m.type.value).toList()
                  : null,
            ),
          );
    } else {
      // Nothing changed, just close dialog
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);
    }
  }

  bool _areMetricsEqual(Set<MetricOption> selected, List<MetricType> groupMetrics) {
    if (selected.length != groupMetrics.length) return false;
    final selectedTypes = selected.map((m) => m.type).toSet();
    return selectedTypes.length == groupMetrics.length &&
        selectedTypes.every((type) => groupMetrics.contains(type));
  }

  void _showInlineMessage(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 5),
  }) {
    _messageTimer?.cancel();
    setState(() {
      _inlineMessage = message;
      _inlineMessageColor = backgroundColor ?? Colors.black.withOpacity(0.85);
    });
    _messageTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _inlineMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state.status == FamilyStatus.groupUpdated) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật thông tin nhóm thành công'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 3),
            ),
          );
        }
        if (state.status == FamilyStatus.error) {
          setState(() {
            _isLoading = false;
          });
          _showInlineMessage(
            state.errorMessage ?? 'Có lỗi xảy ra',
            backgroundColor: AppColors.error,
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.r16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(AppSize.p20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chỉnh sửa nhóm',
                      style: AppTextStyles.h4,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textGrey,
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
                        'Tên nhóm',
                        style: AppTextStyles.labelLarge,
                      ),
                      const SizedBox(height: AppSize.spacing8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập tên nhóm',
                        ),
                        maxLength: _maxGroupNameLength,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên nhóm';
                          }
                          if (value.trim().length > _maxGroupNameLength) {
                            return 'Tên nhóm không được vượt quá $_maxGroupNameLength ký tự';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSize.spacing24),
                const Text(
                  'Chọn các loại dữ liệu được chia sẻ',
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: AppSize.spacing12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableMetrics.map((metric) {
                    final isSelected = _selectedMetrics.contains(metric);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedMetrics.remove(metric);
                          } else {
                            _selectedMetrics.add(metric);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(AppSize.r12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              metric.icon,
                              size: 20,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textGrey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              metric.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textBlack,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_inlineMessage != null) ...[
                  const SizedBox(height: AppSize.spacing16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _inlineMessageColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _inlineMessageColor == AppColors.error
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _inlineMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSize.spacing24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Lưu thay đổi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

