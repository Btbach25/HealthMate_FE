import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/mixins/inline_message_mixin.dart';
import 'package:fe/core/utils/family_bloc_listener_helper.dart';
import 'package:fe/core/utils/metric_helper.dart';
import 'package:fe/core/utils/metric_selection_helper.dart';
import 'package:fe/core/widgets/loading_button.dart';
import 'package:fe/core/widgets/metric_checkbox.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    extends State<EditGroupPermissionsDialog> with InlineMessageMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<MetricType> _selectedMetrics = {};
  bool _isLoading = false;
  
  static const int _maxGroupNameLength = 50;

  @override
  void initState() {
    super.initState();
    // Set current group name
    _nameController.text = widget.group.name;
    // Pre-select current group metrics
    _selectedMetrics.addAll(widget.group.sharedMetrics);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_isLoading) return;

    // Validate form
    if (!_formKey.currentState!.validate()) {
      showInlineMessage(
        'Vui lòng kiểm tra lại thông tin',
        backgroundColor: AppColors.error,
      );
      return;
    }

    if (!MetricSelectionHelper.validateSelection(_selectedMetrics)) {
      showInlineMessage(
        MetricSelectionHelper.getValidationErrorMessage(),
        backgroundColor: AppColors.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newName = _nameController.text.trim();
    final nameChanged = newName != widget.group.name;
    final metricsChanged = MetricSelectionHelper.hasMetricsChanged(
      _selectedMetrics,
      widget.group.sharedMetrics,
    );

    // Only update if something changed
    if (nameChanged || metricsChanged) {
      context.read<FamilyBloc>().add(
            UpdateGroup(
              groupId: widget.group.id,
              name: nameChanged ? newName : null,
              sharedMetrics: metricsChanged
                  ? MetricSelectionHelper.toApiFormat(_selectedMetrics)
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: FamilyBlocListenerHelper.createDialogListener(
        setLoading: () => setState(() => _isLoading = false),
        showInlineMessage: showInlineMessage,
        successStatus: FamilyStatus.groupUpdated,
        successMessage: 'Đã cập nhật thông tin nhóm thành công',
      ),
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
                  children: MetricHelper.availableMetrics.map((metric) {
                    final isSelected = _selectedMetrics.contains(metric.type);
                    return MetricCheckbox(
                      metric: metric,
                      isSelected: isSelected,
                      showCheckbox: false,
                      showCheckIcon: true,
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMetrics.add(metric.type);
                          } else {
                            _selectedMetrics.remove(metric.type);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (buildInlineMessage() != null) ...[
                  const SizedBox(height: AppSize.spacing16),
                  buildInlineMessage()!,
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
                    LoadingButton(
                      text: 'Lưu thay đổi',
                      onPressed: _handleSave,
                      isLoading: _isLoading,
                      width: null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
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

