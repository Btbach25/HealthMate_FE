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
import 'package:fe/data/models/ui/metric_option.dart';
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
  late final List<MetricOption> _supportedMetrics;
  bool _allowMedicationReminderShare = false;
  bool _isLoading = false;
  bool _didEditName = false;
  
  static const int _maxGroupNameLength = 50;

  @override
  void initState() {
    super.initState();
    // Set current group name
    _nameController.text = widget.group.name;
    // Pre-select current group metrics
    _selectedMetrics.addAll(widget.group.sharedMetrics);
    _allowMedicationReminderShare = widget.group.medicationSharingAllowed;
    _supportedMetrics = MetricHelper.availableMetrics
        .where((m) => MetricSelectionHelper.isMetricSupportedByBackend(m.type))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _normalizeName(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
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

    setState(() {
      _isLoading = true;
    });

    final originalName = _normalizeName(widget.group.name);
    final newName = _normalizeName(_nameController.text);
    final nameChanged = _didEditName && newName != originalName;
    final selectedBackendMetricTypes = MetricSelectionHelper
        .filterMetricTypesForBackend(MetricSelectionHelper.toApiFormat(_selectedMetrics));
    final originalBackendMetricTypes = MetricSelectionHelper
        .filterMetricTypesForBackend(widget.group.sharedMetrics.map((m) => m.value).toList());
    final metricsChanged = selectedBackendMetricTypes.toSet() !=
        originalBackendMetricTypes.toSet();
    final medicationChanged =
        _allowMedicationReminderShare != widget.group.medicationSharingAllowed;

    // Only update if something changed
    if (nameChanged || metricsChanged || medicationChanged) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Xác nhận lưu'),
            content: const Text(
              'Bạn có chắc chắn muốn lưu các thay đổi của nhóm không?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() => _isLoading = false);
                },
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<FamilyBloc>().add(
                        UpdateGroup(
                          groupId: widget.group.id,
                          name: nameChanged ? newName : null,
                          sharedMetrics:
                              metricsChanged ? selectedBackendMetricTypes : null,
                          enableMedicationReminderShare:
                              medicationChanged ? _allowMedicationReminderShare : null,
                        ),
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xác nhận'),
              ),
            ],
          );
        },
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSize.p24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Chỉnh sửa nhóm',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textGrey),
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSize.spacing16),
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
                            onChanged: (_) {
                              if (!_didEditName) {
                                setState(() => _didEditName = true);
                              }
                            },
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
                    const SizedBox(height: AppSize.spacing8),
                    Text(
                      'Chọn loại chỉ số được chia sẻ trong nhóm. Nhắc uống thuốc chỉ áp dụng với thành viên đủ quyền — theo cài đặt nhóm và quyền từng người.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: AppSize.spacing8),
                    const Text(
                      'Chọn các loại dữ liệu được chia sẻ',
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: AppSize.spacing12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth =
                            (constraints.maxWidth - AppSize.spacing12) / 2;
                        return Wrap(
                          spacing: AppSize.spacing12,
                          runSpacing: AppSize.spacing12,
                          children: _supportedMetrics
                              .map((metric) {
                                final isSelected =
                                    _selectedMetrics.contains(metric.type);
                                return SizedBox(
                                  width: itemWidth,
                                  child: MetricCheckbox(
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
                                  ),
                                );
                              })
                              .toList()
                            ..add(
                              SizedBox(
                                width: itemWidth,
                                child: _MedicationPermissionTile(
                                  selected: _allowMedicationReminderShare,
                                  onTap: () {
                                    setState(() {
                                      _allowMedicationReminderShare =
                                          !_allowMedicationReminderShare;
                                    });
                                  },
                                ),
                              ),
                            ),
                        );
                      },
                    ),
                    if (buildInlineMessage() != null) ...[
                      const SizedBox(height: AppSize.spacing16),
                      buildInlineMessage()!,
                    ],
                    const SizedBox(height: AppSize.spacing20),
                    LoadingButton(
                      text: 'Lưu thay đổi',
                      onPressed: _handleSave,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicationPermissionTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _MedicationPermissionTile({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSize.p16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(AppSize.r12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.medication_outlined,
                color: selected ? Colors.white : AppColors.textGrey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nhắc nhở uống thuốc',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? AppColors.primaryDark : AppColors.textBlack,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

