import 'package:fe/core/constants/app_styles.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_size.dart';
import '../../../core/theme/app_colors.dart'; 
import '../widgets/featured_metric_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthMate', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // Tương lai sẽ điều hướng đến trang cá nhân
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSize.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lời chào
            Text(
              'Xin chào, ${user.name}! 👋',
              style: AppStyles.h1.copyWith(fontSize: 24),
            ),
            const SizedBox(height: AppSize.p8),
            Text(
              'Hôm nay là ngày tuyệt vời để chăm sóc sức khỏe',
              style: AppStyles.bodyLg,
            ),
            const SizedBox(height: AppSize.p24),
            Row(
              children: [
                FeaturedMetricCard(
                  icon: Icons.favorite_border,
                  label: 'Nhịp tim',
                  value: '75 bpm',
                  iconColor: Colors.red.shade400,
                ),
                const SizedBox(width: AppSize.p16),
                FeaturedMetricCard(
                  icon: Icons.scale_outlined,
                  label: 'Cân nặng',
                  value: '76 kg',
                  iconColor: AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: AppSize.p24),
            Text(
              '(Các phần Huyết áp, Thuốc, Thông báo sẽ ở đây...)',
              style: AppStyles.bodyLg,
            ),
          ],
        ),
      ),
    );
  }
}