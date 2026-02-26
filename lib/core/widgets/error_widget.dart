import 'package:flutter/material.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/constants/app_size.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorDisplayWidget({
    super.key,
    this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSize.p24),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSize.spacing24),
            Text(
              message ?? 'Đã có lỗi xảy ra',
              style: const TextStyle(
                fontSize: AppSize.fontSize18,
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.spacing8),
            Text(
              'Vui lòng thử lại sau',
              style: TextStyle(
                fontSize: AppSize.fontSize14,
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSize.spacing32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSize.p24,
                    vertical: AppSize.p12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSize.r12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


