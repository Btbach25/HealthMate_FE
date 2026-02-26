import 'package:fe/data/repositories/home_repository.dart';

import 'package:fe/presentation/home/bloc/home_bloc.dart';
import 'package:fe/presentation/home/view/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        homeRepository: context.read<HomeRepository>(),
      )..add(FetchHomeData()), // Tự động gọi API khi vào trang
      child: const HomeView(),
    );
  }
}