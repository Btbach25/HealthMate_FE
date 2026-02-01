import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/presentation/family/view/create_group_view.dart';
import 'package:flutter/material.dart';

class CreateGroupDialog extends StatelessWidget {
  final BuildContext rootContext;

  const CreateGroupDialog({
    super.key,
    required this.rootContext,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSize.r24),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(AppSize.p24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Tạo nhóm mới',
                        style: AppTextStyles.h4,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSize.spacing8),
                  Flexible(
                    child: CreateGroupForm(
                      rootContext: rootContext,
                      padding: EdgeInsets.zero,
                      bottomSpacing: 0,
                      onSubmitSuccess: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}








