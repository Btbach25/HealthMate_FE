import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Thanh tiêu đề của màn quản lý nhóm: nút quay lại, tiêu đề và nút "Tạo nhóm".
class FamilyManagementAppBar extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const FamilyManagementAppBar({
    super.key,
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
              onPressed: () => context.pop(),
            ),
            const Expanded(
              child: Text(
                'Quản lý nhóm',
                style: TextStyle(
                  color: AppColors.textBlack,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onCreateGroup,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tạo nhóm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



