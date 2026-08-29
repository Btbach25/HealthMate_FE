import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/metric_helper.dart';
import 'package:fe/core/utils/metric_selection_helper.dart';
import 'package:fe/core/widgets/loading_button.dart';
import 'package:fe/core/widgets/metric_checkbox.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/ui/metric_option.dart';
import 'package:fe/data/services/api_family_service.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dialog thu hẹp bộ chỉ số mà **người dùng hiện tại** chia sẻ riêng cho một
/// thành viên cụ thể. Mở từ nút "Giới hạn" trên thẻ thành viên ở màn chi tiết
/// nhóm; nút chỉ hiện với chủ nhóm và không bao giờ hiện trên thẻ của chính mình.
///
/// Chỉ chọn được trong phạm vi [globalMetrics] (chỉ số nhóm đang cho phép) — tầng
/// riêng luôn hẹp hơn hoặc bằng tầng chung, không thể mở rộng thêm.
///
/// Giá trị ban đầu nạp qua `getMySpecificMetricsForMember`:
/// danh sách rỗng nghĩa là chưa đặt riêng → tick sẵn toàn bộ (kế thừa tầng chung);
/// nếu trả về đúng sentinel `ApiFamilyService.explicitNoMetricsForMember` thì
/// người dùng đã chủ động không chia sẻ gì → để trống.
///
/// Bắn [UpdateMemberPermissions] với `memberId` là **userId**. Tự đóng khi thành công.
class EditMemberPermissionsDialog extends StatefulWidget {
  final String groupId;
  final FamilyMember member;
  final List<MetricType> globalMetrics;
  final bool groupMedicationReminderShareAllowed;

  const EditMemberPermissionsDialog({
    super.key,
    required this.groupId,
    required this.member,
    required this.globalMetrics,
    required this.groupMedicationReminderShareAllowed,
  });

  @override
  State<EditMemberPermissionsDialog> createState() =>
      _EditMemberPermissionsDialogState();
}

class _EditMemberPermissionsDialogState
    extends State<EditMemberPermissionsDialog> {
  final Set<MetricType> _selectedMetrics = {};
  late final List<MetricOption> _supportedMetrics;
  late final Set<MetricType> _allowedByGroup;
  bool _isLoading = false;
  bool _isLoadingPrefill = true;
  bool _allowMedicationReminderShare = false;

  @override
  void initState() {
    super.initState();
    _allowedByGroup = widget.globalMetrics.toSet();
    _supportedMetrics = MetricHelper.availableMetrics
        .where((m) =>
            _allowedByGroup.contains(m.type) &&
            MetricSelectionHelper.isMetricSupportedByBackend(m.type))
        .toList();
    _allowMedicationReminderShare = widget.member.medicationReminderShareAllowed;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrefill());
  }

  /// Nạp giá trị đã lưu cho cặp (tôi → thành viên này). Xem doc lớp về ba trường
  /// hợp: rỗng = kế thừa tầng chung, sentinel = cố tình không chia sẻ, còn lại = bộ đã chọn.
  Future<void> _loadPrefill() async {
    final specifics = await context
        .read<FamilyBloc>()
        .repository
        .getMySpecificMetricsForMember(
          groupId: widget.groupId,
          memberId: widget.member.userId,
        );
    if (!mounted) return;
    setState(() {
      _isLoadingPrefill = false;
      if (specifics.length == 1 &&
          specifics.first == ApiFamilyService.explicitNoMetricsForMember) {
        return;
      }
      if (specifics.isEmpty) {
        _selectedMetrics.addAll(_allowedByGroup);
      } else {
        for (final s in specifics) {
          try {
            final t = MetricType.fromValue(s);
            if (_allowedByGroup.contains(t)) _selectedMetrics.add(t);
          } catch (_) {}
        }
      }
    });
  }

  void _handleSave() {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    context.read<FamilyBloc>().add(
          UpdateMemberPermissions(
            groupId: widget.groupId,
            memberId: widget.member.userId,
            sharedMetrics: MetricSelectionHelper.toApiFormat(_selectedMetrics),
            allowMedicationReminderShare:
                widget.groupMedicationReminderShareAllowed
                    ? _allowMedicationReminderShare
                    : false,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state.status == FamilyStatus.memberPermissionsUpdated) {
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật quyền chia sẻ cho thành viên'),
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
              child: _isLoadingPrefill
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSize.p24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giới hạn chỉ số tôi chia cho ${widget.member.name}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textBlack,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Thành viên: ${widget.member.name}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textGrey.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                        'Bạn đang thu hẹp chỉ số chia sẻ riêng với thành viên này, trong phạm vi chỉ số bạn đã chia sẻ với nhóm.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: AppSize.spacing16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _supportedMetrics.map((metric) {
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
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSize.spacing12),
                    InkWell(
                      onTap: widget.groupMedicationReminderShareAllowed
                          ? () => setState(() {
                                _allowMedicationReminderShare =
                                    !_allowMedicationReminderShare;
                              })
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _allowMedicationReminderShare
                              ? AppColors.primaryContainer
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _allowMedicationReminderShare
                                ? AppColors.primary
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 18,
                              color: _allowMedicationReminderShare
                                  ? AppColors.primary
                                  : AppColors.textGrey,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Nhắc thuốc')),
                            Icon(
                              _allowMedicationReminderShare
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: _allowMedicationReminderShare
                                  ? AppColors.primary
                                  : AppColors.textLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!widget.groupMedicationReminderShareAllowed) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Nhóm chưa bật quyền chia sẻ nhắc thuốc.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSize.spacing24),
                    LoadingButton(
                      text: 'Lưu quyền',
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
