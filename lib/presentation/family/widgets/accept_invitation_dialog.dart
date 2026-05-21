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
  // Metrics nhóm cho phép chia sẻ — lấy từ invitationPreviewDetails.group.sharedMetrics
  // (invitation.sharedMetrics từ BE luôn rỗng vì lời mời chỉ mang email, không mang metrics)
  Set<MetricType> _groupAllowedMetrics = {};
  bool _previewLoaded = false;

  @override
  void initState() {
    super.initState();
    // Fallback: nếu invitation đã có shared_metrics, dùng luôn
    if (widget.invitation.sharedMetrics.isNotEmpty) {
      _onPreviewSettled(widget.invitation.sharedMetrics.toSet());
    }
    // Cố gắng load full preview (members list, etc)
    context.read<FamilyBloc>().add(
      FetchInvitationPreview(groupId: widget.invitation.groupId),
    );
  }

  void _onPreviewSettled(Set<MetricType> groupMetrics) {
    if (!mounted) return;
    setState(() {
      _previewLoaded = true;
      _groupAllowedMetrics = groupMetrics;
      _selectedMetrics
        ..clear()
        ..addAll(groupMetrics);
    });
  }

  void _handleAccept() {
    if (_isLoading) return;
    
    if (_selectedMetrics.isEmpty && _groupAllowedMetrics.isNotEmpty) {
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
        sharedMetrics: MetricSelectionHelper.toApiFormat(
          _selectedMetrics.intersection(_groupAllowedMetrics),
        ),
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
        // Không navigate vào nhóm ngay: user phải chờ chủ nhóm duyệt.
        // Toast "chờ duyệt" được hiển thị bởi FamilyGroupManagementView.BlocListener.
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
                              if (state.status == FamilyStatus.invitationPreviewLoaded) {
                                final metrics = state.invitationPreviewDetails
                                        ?.group.sharedMetrics
                                        .toSet() ??
                                    {};
                                _onPreviewSettled(metrics);
                              } else if (state.status == FamilyStatus.error &&
                                  state.invitationPreviewGroupId == widget.invitation.groupId) {
                                // Fallback: lấy metrics từ invitation object (set bởi inviter)
                                _onPreviewSettled(
                                  widget.invitation.sharedMetrics.toSet(),
                                );
                              }
                            },
                            builder: (context, state) =>
                                _buildInvitationPreview(state),
                          ),
                          const SizedBox(height: AppSize.spacing16),
                          if (!_previewLoaded)
                            const SizedBox(height: 8)
                          else if (_groupAllowedMetrics.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: const Text(
                                'Hiện chủ nhóm chưa bật quyền chia sẻ chỉ số nào cho lời mời này.',
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
                                    .where((m) => _groupAllowedMetrics.contains(m.type))
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
                            final canAccept = _previewLoaded;
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

    // Fallback: use invitation.group if preview details not available
    if (details == null && widget.invitation.group == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          'Không tải được chi tiết nhóm, bạn vẫn có thể dựa vào lời mời để quyết định.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
        ),
      );
    }

    final groupName = details?.group.name ?? widget.invitation.group?.name ?? 'Nhóm';
    final memberCount = details?.members.length ?? widget.invitation.group?.memberCount ?? 0;
    final members = details?.members ?? [];

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
            groupName,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Thành viên hiện tại: $memberCount',
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


