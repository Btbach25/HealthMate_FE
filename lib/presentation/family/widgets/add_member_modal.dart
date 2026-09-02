import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/mixins/inline_message_mixin.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/family_bloc_listener_helper.dart';
import 'package:fe/core/utils/form_validation_helper.dart';
import 'package:fe/core/widgets/loading_button.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/enums/relationship_type.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Modal mời thành viên mới bằng email — chỉ mở từ màn chi tiết nhóm.
///
/// Chỉ gửi email và mối quan hệ: `sharedMetrics` cố tình để rỗng vì người được
/// mời tự chọn chỉ số chia sẻ của họ trong [AcceptInvitationDialog], chủ nhóm
/// không quyết thay. Email phải là tài khoản đã đăng ký, nếu không BE trả lỗi.
///
/// Bắn [InviteMember]; thành công thì đóng modal, không trả về giá trị.
class AddMemberModal extends StatefulWidget {
  final String groupId;

  /// Bộ chỉ số nhóm đang cho phép. Hiện chỉ để tham chiếu/dự phòng — form không
  /// còn cho chủ nhóm chọn hộ chỉ số của người được mời nữa.
  final List<MetricType> groupAllowedMetrics;

  const AddMemberModal({
    super.key,
    required this.groupId,
    required this.groupAllowedMetrics,
  });

  @override
  State<AddMemberModal> createState() => _AddMemberModalState();
}

class _AddMemberModalState extends State<AddMemberModal>
    with InlineMessageMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  RelationshipType? _selectedRelationship;
  bool _isLoading = false;

  static final List<RelationshipType> _relationships = RelationshipType.all;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleInvite() {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      showInlineMessage(
        'Vui lòng điền đầy đủ thông tin',
        backgroundColor: AppColors.error,
      );
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
    });

    context.read<FamilyBloc>().add(
      InviteMember(
        groupId: widget.groupId,
        email: email,
        relationship: _selectedRelationship?.value,
        age: null,
        sharedMetrics: const [],
        userId: null,
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Padding(
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
                      'Thêm thành viên mới',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập email tài khoản đã đăng ký. Sau khi được duyệt, '
                      'thành viên tự chọn chỉ số chia sẻ trong nhóm.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey.withValues(alpha: 0.8),
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
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Nhập email đã đăng ký để gửi lời mời',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    return FormValidationHelper.validateEmail(value);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mối quan hệ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RelationshipType>(
                  initialValue: _selectedRelationship,
                  decoration: const InputDecoration(
                    hintText: 'Chọn mối quan hệ',
                  ),
                  items: _relationships.map((rel) {
                    return DropdownMenuItem(
                      value: rel,
                      child: Text(rel.displayLabel),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRelationship = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Người được mời sẽ tự cấu hình chỉ số chia sẻ sau khi bạn duyệt tham gia nhóm.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (buildInlineMessage() != null) ...[
            buildInlineMessage()!,
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          LoadingButton(
            text: 'Gửi lời mời',
            onPressed: _handleInvite,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: FamilyBlocListenerHelper.createDialogListener(
        setLoading: () => setState(() => _isLoading = false),
        showInlineMessage: showInlineMessage,
        successStatus: FamilyStatus.memberInvited,
        successMessage: 'Đã gửi lời mời thành công',
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Luôn cho phép cuộn dọc nếu nội dung cao hơn khung,
                  // trên màn hình cao thì hầu như không cần cuộn.
                  return SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    child: _buildDialogContent(context),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
