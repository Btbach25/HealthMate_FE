import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/form_validation_helper.dart';
import 'package:fe/core/utils/metric_helper.dart';
import 'package:fe/core/utils/metric_selection_helper.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/core/widgets/loading_button.dart';
import 'package:fe/core/widgets/metric_checkbox.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/ui/metric_option.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Hai bước của luồng tạo nhóm: đặt tên rồi mới chọn quyền chia sẻ.
enum _Step { name, metrics }

/// Dialog tạo nhóm 2 bước. Ai cũng mở được (người tạo trở thành chủ nhóm).
/// Mở từ tab Gia đình, màn quản lý nhóm, hoặc deep link `/family/create`.
///
/// Bước 1 bắn [CreateGroupName] → `groupNameCreated`: nhóm đã tồn tại trên server
/// với `createdGroupId`. Bước 2 bắn [UpdateGroup] → `groupUpdated` rồi đóng dialog.
/// Vì bước 1 đã tạo nhóm thật, thoát giữa chừng ở bước 2 sẽ hỏi xác nhận và để lại
/// một nhóm chưa cấu hình chia sẻ — người dùng chỉnh sau ở màn chi tiết nhóm.
///
/// Không trả về giá trị; kết quả thành công báo bằng snackbar trên [rootContext]
/// (context của dialog đã bị huỷ khi snackbar hiện).
class CreateGroupDialog extends StatefulWidget {
  /// Context còn sống sau khi dialog đóng, dùng để hiện snackbar thành công.
  final BuildContext rootContext;

  const CreateGroupDialog({
    super.key,
    required this.rootContext,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  _Step _step = _Step.name;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmittingName = false;

  final Set<MetricType> _selectedMetrics = {};
  bool _allowMedication = false;
  bool _isSubmittingMetrics = false;
  String? _metricsError;
  String _createdGroupId = '';
  String _groupName = '';

  late final List<MetricOption> _availableMetrics;

  @override
  void initState() {
    super.initState();
    _availableMetrics = MetricHelper.availableMetrics
        .where((m) => MetricSelectionHelper.isMetricSupportedByBackend(m.type))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Bước 1: tạo nhóm với tên. Kết quả về qua status `groupNameCreated`.
  void _submitName() {
    if (_isSubmittingName) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmittingName = true);
    FocusScope.of(context).unfocus();
    _groupName = _nameController.text.trim();
    context.read<FamilyBloc>().add(CreateGroupName(name: _groupName));
  }

  /// Bước 2: lưu quyền chia sẻ cho nhóm vừa tạo. Về qua status `groupUpdated`.
  void _submitMetrics() {
    if (_isSubmittingMetrics) return;
    if (!MetricSelectionHelper.validateSelection(_selectedMetrics)) {
      setState(() => _metricsError = MetricSelectionHelper.getValidationErrorMessage());
      return;
    }
    setState(() {
      _isSubmittingMetrics = true;
      _metricsError = null;
    });
    context.read<FamilyBloc>().add(
          UpdateGroup(
            groupId: _createdGroupId,
            sharedMetrics: MetricSelectionHelper.toApiFormat(_selectedMetrics),
            enableMedicationReminderShare: _allowMedication,
          ),
        );
  }

  /// Xác nhận trước khi bỏ dở bước 2 — nhóm đã được tạo ở bước 1 nên đóng dialog
  /// không hề huỷ nhóm, người dùng cần biết điều đó.
  Future<void> _tryCloseStep2() async {
    if (_isSubmittingMetrics) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thoát không cài đặt?'),
        content: const Text(
          'Nhóm đã được tạo nhưng chưa cài đặt chỉ số chia sẻ. '
          'Bạn có thể cài đặt sau trong chi tiết nhóm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tiếp tục'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Bỏ qua',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state.status == FamilyStatus.groupNameCreated && _isSubmittingName) {
          setState(() {
            _isSubmittingName = false;
            _createdGroupId = state.createdGroupId ?? '';
            _step = _Step.metrics;
          });
        } else if (state.status == FamilyStatus.groupUpdated && _isSubmittingMetrics) {
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            SnackBar(
              content: Text('Tạo nhóm "$_groupName" thành công'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state.status == FamilyStatus.error) {
          if (_isSubmittingName) setState(() => _isSubmittingName = false);
          if (_isSubmittingMetrics) setState(() => _isSubmittingMetrics = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(UserFacingError.message(state.errorMessage)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
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
              elevation: 0,
              child: _step == _Step.name ? _buildStep1() : _buildStep2(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSize.p24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Tạo nhóm mới', style: AppTextStyles.h4),
                const Spacer(),
                IconButton(
                  onPressed: _isSubmittingName ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textGrey),
                ),
              ],
            ),
            const SizedBox(height: AppSize.spacing16),
            const Text('Tên nhóm', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSize.spacing8),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Nhập tên nhóm'),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitName(),
              validator: (value) =>
                  FormValidationHelper.validateRequired(value, fieldName: 'tên nhóm') ??
                  FormValidationHelper.validateMinLength(value, 3, fieldName: 'Tên nhóm') ??
                  FormValidationHelper.validateMaxLength(value, 100, fieldName: 'Tên nhóm'),
            ),
            const SizedBox(height: AppSize.spacing24),
            LoadingButton(
              text: 'Tiếp theo',
              onPressed: _submitName,
              isLoading: _isSubmittingName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSize.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cài đặt chia sẻ', style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Text(
                      'Bước 2/2 — Chọn chỉ số chia sẻ trong nhóm',
                      style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _tryCloseStep2,
                icon: const Icon(Icons.close, color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(height: AppSize.spacing12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'Chọn ít nhất 1 chỉ số sức khỏe bạn muốn chia sẻ với nhóm. '
              'Bạn có thể thay đổi sau trong chi tiết nhóm.',
              style: AppTextStyles.caption,
            ),
          ),
          const SizedBox(height: AppSize.spacing16),
          if (_metricsError != null) ...[
            Text(
              _metricsError!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
            const SizedBox(height: AppSize.spacing8),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableMetrics.map((metric) {
              final isSelected = _selectedMetrics.contains(metric.type);
              return MetricCheckbox(
                metric: metric,
                isSelected: isSelected,
                width: 180,
                showCheckbox: false,
                showCheckIcon: true,
                onChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedMetrics.add(metric.type);
                    } else {
                      _selectedMetrics.remove(metric.type);
                    }
                    if (_selectedMetrics.isNotEmpty) _metricsError = null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSize.spacing12),
          InkWell(
            onTap: () => setState(() => _allowMedication = !_allowMedication),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 180,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _allowMedication ? AppColors.primaryContainer : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _allowMedication ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 18,
                    color: _allowMedication ? AppColors.primary : AppColors.textGrey,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Nhắc thuốc')),
                  Icon(
                    _allowMedication ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: _allowMedication ? AppColors.primary : AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSize.spacing24),
          LoadingButton(
            text: 'Tạo nhóm',
            onPressed: _submitMetrics,
            isLoading: _isSubmittingMetrics,
          ),
        ],
      ),
    );
  }
}
