import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/metric_helper.dart';
import 'package:fe/core/utils/metric_selection_helper.dart';
import 'package:fe/core/widgets/loading_button.dart';
import 'package:fe/core/widgets/metric_checkbox.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/ui/metric_option.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dialog người dùng tự chọn bộ chỉ số **của mình** chia sẻ với cả nhóm.
/// Mọi thành viên đều mở được, nhưng chỉ cho chính mình — vào từ nút
/// "Chia sẻ chỉ số" trên thẻ của bản thân, hoặc từ banner nhắc chưa chia sẻ.
///
/// Bắn [UpdateMySharing]; đây là tầng quyền chung. Chủ nhóm vẫn có thể thu hẹp
/// thêm ở tầng riêng ([EditMemberPermissionsDialog]). Tự đóng khi thành công.
class EditMySharingDialog extends StatefulWidget {
  final String groupId;
  final List<MetricType> currentMetrics;

  const EditMySharingDialog({
    super.key,
    required this.groupId,
    required this.currentMetrics,
  });

  @override
  State<EditMySharingDialog> createState() => _EditMySharingDialogState();
}

class _EditMySharingDialogState extends State<EditMySharingDialog> {
  final Set<MetricType> _selectedMetrics = {};
  late final List<MetricOption> _availableMetrics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _availableMetrics = MetricHelper.availableMetrics
        .where((m) => MetricSelectionHelper.isMetricSupportedByBackend(m.type))
        .toList();
    _selectedMetrics.addAll(widget.currentMetrics);
  }

  void _handleSave() {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    context.read<FamilyBloc>().add(
      UpdateMySharing(
        groupId: widget.groupId,
        sharedMetrics: MetricSelectionHelper.toApiFormat(_selectedMetrics),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state.status == FamilyStatus.mySharingUpdated) {
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật chỉ số chia sẻ với nhóm'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.status == FamilyStatus.error && _isLoading) {
          setState(() => _isLoading = false);
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSize.p24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Chia sẻ chỉ số của tôi',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textGrey,
                          ),
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
                        'Chọn chỉ số sức khỏe bạn muốn chia sẻ với các thành viên trong nhóm. Chủ nhóm có thể giới hạn thêm cho từng người.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: AppSize.spacing16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableMetrics.map((metric) {
                        final isSelected = _selectedMetrics.contains(
                          metric.type,
                        );
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
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSize.spacing24),
                    LoadingButton(
                      text: 'Lưu',
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
