import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/mixins/inline_message_mixin.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/core/utils/form_validation_helper.dart';
import 'package:fe/core/utils/metric_helper.dart';
import 'package:fe/core/utils/metric_selection_helper.dart';
import 'package:fe/core/widgets/loading_button.dart';
import 'package:fe/core/widgets/metric_checkbox.dart';
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
          constraints: const BoxConstraints(maxWidth: AppSize.shellMaxWidth),
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

class _CreateGroupFormState extends State<CreateGroupForm>
    with InlineMessageMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<MetricType> _selectedMetrics = {};
  String? _metricsError;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleCreateGroup() {
    if (_isLoading) return;
    
    if (!_formKey.currentState!.validate()) {
      showInlineMessage(
        'Vui lòng điền đầy đủ thông tin',
        backgroundColor: AppColors.error,
      );
      return;
    }

    if (!MetricSelectionHelper.validateSelection(_selectedMetrics)) {
      setState(() {
        _metricsError = MetricSelectionHelper.getValidationErrorMessage();
      });
      showInlineMessage(
        MetricSelectionHelper.getValidationErrorMessage(),
        backgroundColor: AppColors.error,
      );
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
            sharedMetrics: MetricSelectionHelper.toApiFormat(_selectedMetrics),
          ),
        );
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
        if (state.status == FamilyStatus.groupCreated &&
            state.createdGroupName != null) {
          setState(() {
            _isLoading = false;
          });
          final groupName = state.createdGroupName!;
          // Dùng SnackBar vì sau đó có thể `Navigator.pop()` nên inline message
          // phụ thuộc widget còn sống dễ không kịp hiển thị.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tạo nhóm "$groupName" thành công'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 4),
            ),
          );
          _resetForm();
          widget.onSubmitSuccess?.call();
        }
        if (state.status == FamilyStatus.error) {
          setState(() {
            _isLoading = false;
          });
          showInlineMessage(
            UserFacingError.message(state.errorMessage),
            backgroundColor: AppColors.error,
          );
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
                      final req = FormValidationHelper.validateRequired(
                        value,
                        fieldName: 'tên nhóm',
                      );
                      if (req != null) return req;
                      final min = FormValidationHelper.validateMinLength(
                        value,
                        3,
                        fieldName: 'Tên nhóm',
                      );
                      if (min != null) return min;
                      return FormValidationHelper.validateMaxLength(
                        value,
                        100,
                        fieldName: 'Tên nhóm',
                      );
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
                    'Chọn các chỉ số sức khỏe bạn muốn chia sẻ với nhóm (hiện hỗ trợ: nhịp tim, bước chân, calo)',
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
                        children: MetricHelper.availableMetrics
                            .where((m) => MetricSelectionHelper.isMetricSupportedByBackend(m.type))
                            .map(
                              (metric) => SizedBox(
                                width: itemWidth,
                                child: MetricCheckbox(
                                  metric: metric,
                                  isSelected: _selectedMetrics.contains(metric.type),
                                  showCheckbox: false,
                                  showCheckIcon: true,
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedMetrics.add(metric.type);
                                      } else {
                                        _selectedMetrics.remove(metric.type);
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
                  if (buildInlineMessage() != null) ...[
                    buildInlineMessage()!,
                    const SizedBox(height: AppSize.spacing16),
                  ],
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSize.r12),
                      boxShadow: AppColors.buttonShadow,
                    ),
                    child: LoadingButton(
                      text: 'Tạo nhóm',
                      onPressed: _handleCreateGroup,
                      isLoading: isSubmitting,
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSize.p16),
                      borderRadius: BorderRadius.circular(AppSize.r12),
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


