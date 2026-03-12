import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/mixins/inline_message_mixin.dart';
import 'package:fe/core/utils/family_bloc_listener_helper.dart';
import 'package:fe/core/utils/metric_helper.dart';
import 'package:fe/core/utils/metric_selection_helper.dart';
import 'package:fe/core/widgets/loading_button.dart';
import 'package:fe/core/widgets/metric_checkbox.dart';
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

class _AcceptInvitationDialogState extends State<AcceptInvitationDialog>
    with InlineMessageMixin {
  final Set<MetricType> _selectedMetrics = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-select metrics from invitation
    _selectedMetrics.addAll(widget.invitation.sharedMetrics);
  }

  void _handleAccept() {
    if (_isLoading) return;
    
    if (_selectedMetrics.isEmpty) {
      showInlineMessage(
        'Vui lòng chọn ít nhất một loại chỉ số để chia sẻ',
        backgroundColor: AppColors.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    context.read<FamilyBloc>().add(
          AcceptInvitation(
            groupId: widget.invitation.groupId,
            sharedMetrics: MetricSelectionHelper.toApiFormat(_selectedMetrics),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: FamilyBlocListenerHelper.createDialogListener(
        setLoading: () => setState(() => _isLoading = false),
        showInlineMessage: showInlineMessage,
        successStatus: FamilyStatus.invitationAccepted,
        shouldPop: true,
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
                                  color: AppColors.textGrey.withValues(alpha:0.8),
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
                      children: MetricHelper.availableMetrics.map((metric) {
                        final isSelected = _selectedMetrics.contains(metric.type);
                        return MetricCheckbox(
                          metric: metric,
                          isSelected: isSelected,
                          width: 180,
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
                    const SizedBox(height: 20),
                    if (buildInlineMessage() != null) ...[
                      buildInlineMessage()!,
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    LoadingButton(
                      text: 'Chấp nhận và tham gia',
                      onPressed: _handleAccept,
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


