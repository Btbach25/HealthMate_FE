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
import 'package:fe/data/models/group/group_details.dart';
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
  late final Set<MetricType> _selectableMetrics;
  bool _previewLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectableMetrics = MetricHelper.availableMetrics
        .where((m) => MetricSelectionHelper.isMetricSupportedByBackend(m.type))
        .map((m) => m.type)
        .toSet();
    _selectedMetrics.addAll(_selectableMetrics);
    context.read<FamilyBloc>().add(
      FetchInvitationPreview(groupId: widget.invitation.groupId),
    );
  }

  void _onPreviewLoaded() {
    if (!mounted) return;
    setState(() => _previewLoaded = true);
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
        currentMemberCount: widget.invitation.memberCount,
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
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        border: Border(
                          bottom: BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text(
                              'Gửi yêu cầu tham gia',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textBlack,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Yêu cầu sẽ được gửi đến chủ nhóm để duyệt. Bạn sẽ chính thức tham gia sau khi được chấp thuận.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textBlack,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chọn chỉ số sức khỏe bạn muốn chia sẻ trong nhóm này.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: AppSize.spacing12),
                          BlocConsumer<FamilyBloc, FamilyState>(
                            buildWhen: (previous, current) =>
                                previous.status != current.status ||
                                previous.invitationPreviewGroupId !=
                                    current.invitationPreviewGroupId ||
                                previous.invitationPreviewDetails !=
                                    current.invitationPreviewDetails,
                            listenWhen: (previous, current) {
                              final wasLoadingThis =
                                  previous.status ==
                                      FamilyStatus.invitationPreviewLoading &&
                                  previous.invitationPreviewGroupId ==
                                      widget.invitation.groupId;
                              final isNowLoaded = current.status ==
                                      FamilyStatus.invitationPreviewLoaded &&
                                  current.invitationPreviewGroupId ==
                                      widget.invitation.groupId;
                              return isNowLoaded ||
                                  (wasLoadingThis &&
                                      current.status == FamilyStatus.error);
                            },
                            listener: (context, state) {
                              _onPreviewLoaded();
                            },
                            builder: (context, state) =>
                                _buildInvitationPreview(state),
                          ),
                          const SizedBox(height: AppSize.spacing16),
                          if (_selectableMetrics.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: const Text(
                                'Không có loại chỉ số khả dụng. Vui lòng thử lại sau.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                  height: 1.35,
                                ),
                              ),
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxWidth < 360;
                                final columns = isCompact ? 1 : 2;
                                final itemWidth = columns == 1
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - AppSize.spacing12) / 2;
                                final allowedMetrics = MetricHelper.availableMetrics
                                    .where((m) => _selectableMetrics.contains(m.type))
                                    .toList();
                                return Wrap(
                                  spacing: AppSize.spacing12,
                                  runSpacing: AppSize.spacing12,
                                  children: allowedMetrics.map((metric) {
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
                                  }).toList(),
                                );
                              },
                            ),
                          const SizedBox(height: 20),
                          if (buildInlineMessage() != null) ...[
                            buildInlineMessage()!,
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),
                          Builder(builder: (context) {
                            final canAccept =
                                _previewLoaded && _selectableMetrics.isNotEmpty;
                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: canAccept
                                    ? AppColors.primaryGradient
                                    : null,
                                color: canAccept
                                    ? null
                                    : AppColors.textGrey.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(AppSize.r12),
                                boxShadow:
                                    canAccept ? AppColors.buttonShadow : null,
                              ),
                              child: LoadingButton(
                                text: 'Gửi yêu cầu tham gia',
                                onPressed: canAccept ? _handleAccept : null,
                                isLoading: _isLoading,
                                backgroundColor: Colors.transparent,
                                foregroundColor:
                                    canAccept ? Colors.white : AppColors.textGrey,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSize.p16),
                                borderRadius:
                                    BorderRadius.circular(AppSize.r12),
                              ),
                            );
                          }),
                        ],
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

  Widget _buildInvitationPreview(FamilyState state) {
    final isLoadingPreview =
        state.status == FamilyStatus.invitationPreviewLoading &&
        state.invitationPreviewGroupId == widget.invitation.groupId;
    final GroupDetails? details =
        state.invitationPreviewGroupId == widget.invitation.groupId
        ? state.invitationPreviewDetails
        : null;

    if (isLoadingPreview) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 3),
      );
    }

    if (details == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          'Không tải được chi tiết nhóm, bạn vẫn có thể gửi yêu cầu tham gia.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
        ),
      );
    }

    final members = details.members;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            details.group.name,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Thành viên hiện tại: ${members.length}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: 8),
          ...members.take(5).map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '- ${m.name}${(m.relationship ?? '').isNotEmpty ? ' (${m.relationship})' : ''}',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ),
          if (members.length > 5)
            Text(
              '... và ${members.length - 5} thành viên khác',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
            ),
        ],
      ),
    );
  }
}
