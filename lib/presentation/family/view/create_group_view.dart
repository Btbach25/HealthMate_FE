import 'dart:async';

import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreateGroupView extends StatelessWidget {
  const CreateGroupView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 100;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tạo nhóm mới',
          style: AppTextStyles.h4,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: CreateGroupForm(
            rootContext: context,
            padding: EdgeInsets.only(
              left: AppSize.p16,
              right: AppSize.p16,
              top: AppSize.p16,
              bottom: AppSize.p16 + bottomInset,
            ),
            bottomSpacing: bottomInset,
            onSubmitSuccess: () => context.pop(),
          ),
        ),
      ),
    );
  }
}

class CreateGroupForm extends StatefulWidget {
  final BuildContext rootContext;
  final EdgeInsetsGeometry padding;
  final double bottomSpacing;
  final VoidCallback? onSubmitSuccess;

  const CreateGroupForm({
    super.key,
    required this.rootContext,
    this.padding = const EdgeInsets.all(AppSize.p16),
    this.bottomSpacing = 0,
    this.onSubmitSuccess,
  });

  @override
  State<CreateGroupForm> createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends State<CreateGroupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<MetricOption> _selectedMetrics = {};
  String? _metricsError;
  String? _inlineMessage;
  Color? _inlineMessageColor;
  Timer? _messageTimer;
  bool _isLoading = false;

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
  void dispose() {
    _nameController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _handleCreateGroup() {
    if (_isLoading) return;
    
    if (!_formKey.currentState!.validate()) {
      _showInlineMessage('Vui lòng điền đầy đủ thông tin');
      return;
    }

    if (_selectedMetrics.isEmpty) {
      setState(() {
        _metricsError = 'Vui lòng chọn ít nhất một chỉ số để chia sẻ';
      });
      _showInlineMessage('Vui lòng chọn ít nhất một chỉ số để chia sẻ');
      return;
    }

    if (_metricsError != null) {
      setState(() {
        _metricsError = null;
      });
    }

    setState(() {
      _isLoading = true;
    });

    FocusScope.of(context).unfocus();
    context.read<FamilyBloc>().add(
          CreateGroup(
            name: _nameController.text.trim(),
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

  void _resetForm() {
    _nameController.clear();
    setState(() {
      _selectedMetrics.clear();
      _metricsError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state.status == FamilyStatus.error) {
          _showInlineMessage(
            state.errorMessage ?? 'Có lỗi xảy ra',
            backgroundColor: AppColors.error,
          );
        }

        if (state.status == FamilyStatus.groupCreated &&
            state.createdGroupName != null) {
          setState(() {
            _isLoading = false;
          });
          final groupName = state.createdGroupName!;
          _showInlineMessage(
            'Tạo nhóm "$groupName" thành công',
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          );
          _resetForm();
          widget.onSubmitSuccess?.call();
        }
        if (state.status == FamilyStatus.error) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      child: BlocBuilder<FamilyBloc, FamilyState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          final isSubmitting = state.status == FamilyStatus.creatingGroup;
          return SingleChildScrollView(
            padding: widget.padding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSize.spacing8),
                  Text(
                    'Tạo nhóm gia đình mới để quản lý và chia sẻ thông tin sức khỏe',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: AppSize.spacing24),
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên nhóm';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSize.spacing24),
                  const Text(
                    'Quyền truy cập dữ liệu',
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: AppSize.spacing8),
                if (_metricsError != null) ...[
                  Text(
                    _metricsError!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSize.spacing4),
                ],
                  Text(
                    'Chọn các chỉ số sức khỏe bạn muốn chia sẻ với nhóm',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: AppSize.spacing16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth =
                          (constraints.maxWidth - AppSize.spacing12) / 2;
                      return Wrap(
                        spacing: AppSize.spacing12,
                        runSpacing: AppSize.spacing12,
                        children: _availableMetrics
                            .map(
                              (metric) => SizedBox(
                                width: itemWidth,
                                child: _MetricCheckbox(
                                  metric: metric,
                                  isSelected: _selectedMetrics
                                      .any((m) => m.type == metric.type),
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedMetrics.add(metric);
                                      } else {
                                        _selectedMetrics.removeWhere(
                                          (m) => m.type == metric.type,
                                        );
                                      }

                                      if (_selectedMetrics.isNotEmpty &&
                                          _metricsError != null) {
                                        _metricsError = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSize.spacing24),
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
                    const SizedBox(height: AppSize.spacing16),
                  ],
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSize.r12),
                      boxShadow: AppColors.buttonShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _handleCreateGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSize.p16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSize.r12),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
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
                              'Tạo nhóm',
                              style: AppTextStyles.buttonLarge,
                            ),
                    ),
                  ),
                  if (widget.bottomSpacing > 0)
                    SizedBox(height: widget.bottomSpacing),
                ],
              ),
            ),
          );
        },
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
              ? AppColors.primaryContainer
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSize.r12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppColors.cardShadowList : null,
        ),
        child: Row(
          children: [
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
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                metric.label,
                style: isSelected
                    ? AppTextStyles.labelLarge
                    : AppTextStyles.bodyMedium,
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textGrey,
            ),
          ],
        ),
      ),
    );
  }
}

