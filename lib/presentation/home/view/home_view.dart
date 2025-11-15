import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/presentation/home/bloc/home_bloc.dart';
import 'package:fe/presentation/home/widgets/home_app_bar.dart';
import 'package:fe/presentation/home/widgets/medication_card.dart';
import 'package:fe/presentation/home/widgets/notification_list.dart';
import 'package:fe/presentation/home/widgets/stats_grid.dart';
import 'package:fe/presentation/home/widgets/welcome_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.initial ||
              state.status == HomeStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == HomeStatus.error) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Đã có lỗi xảy ra',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          if (state.status == HomeStatus.loaded && state.homeData != null) {
            final homeData = state.homeData!;
            final user = homeData.user;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeAppBar(user: user),
                      const SizedBox(height: 24),

                      WelcomeMessage(name: user.name),
                      const SizedBox(height: 24),

                      StatsGrid(user: user),
                      const SizedBox(height: 24),

                      if (homeData.medicationProgress != null)
                        MedicationCard(progress: homeData.medicationProgress!),
                      
                      const SizedBox(height: 24),

                      NotificationList(notifications: homeData.notifications),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          }

          return const Center(child: Text('Trạng thái không xác định'));
        },
      ),
    );
  }
}