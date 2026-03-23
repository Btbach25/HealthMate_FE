import 'package:fe/data/repositories/stats_repository.dart';
import 'package:fe/presentation/details/bloc/stats_bloc.dart';
import 'package:fe/presentation/details/view/stats_view.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatsBloc(
        statsRepository: context.read<StatsRepository>(),
        deviceCubit: context.read<DeviceHealthCubit>(),
      )..add(FetchStatsData()),
      child: const StatsView(),
    );
  }
}