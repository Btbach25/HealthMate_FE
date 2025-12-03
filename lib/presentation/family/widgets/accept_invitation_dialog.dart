import 'dart:async';
import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AcceptInvitationDialog extends StatefulWidget {
  final IncomingInvitation invitation;

  const AcceptInvitationDialog({
    super.key,
    required this.invitation,
  });

  @override
  State<AcceptInvitationDialog> createState() => _AcceptInvitationDialogState();
}

class _AcceptInvitationDialogState extends State<AcceptInvitationDialog> {
  final Set<MetricType> _selectedMetrics = {};
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
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select metrics from invitation
    _selectedMetrics.addAll(widget.invitation.sharedMetrics);
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
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
        setState(() => _inlineMessage = null);
      }
    });
  }

  void _handleAccept() {
    if (_isLoading) return;
    
    if (_selectedMetrics.isEmpty) {
      _showInlineMessage('Vui lòng chọn ít nhất một loại chỉ số để chia sẻ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    context.read<FamilyBloc>().add(
          AcceptInvitation(
            invitationId: widget.invitation.id,
            sharedMetrics: _selectedMetrics.map((m) => m.value).toList(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state.status == FamilyStatus.invitationAccepted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pop(context);
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chọn chỉ số chia sẻ',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textBlack,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Chọn các chỉ số sức khỏe bạn muốn chia sẻ với nhóm "${widget.invitation.groupName}"',
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableMetrics.map((metric) {
                        final isSelected = _selectedMetrics.contains(metric.type);
                        return SizedBox(
                          width: 180,
                          child: _MetricCheckbox(
                            metric: metric,
                            isSelected: isSelected,
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
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
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
                        onPressed: _isLoading ? null : _handleAccept,
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
                                'Chấp nhận và tham gia',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
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

