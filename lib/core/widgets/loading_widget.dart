import 'package:flutter/material.dart';
import 'package:fe/core/theme/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isFullScreen;

  const LoadingWidget({
    super.key,
    this.message,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          strokeWidth: 3,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
}


