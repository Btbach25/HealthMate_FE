import 'package:fe/data/repositories/home_repository.dart';
import 'package:fe/presentation/home/bloc/home_bloc.dart';
import 'package:fe/presentation/home/view/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Điểm vào của tab "Tổng quan" (route khai báo trong `core/routing/app_router.dart`).
///
/// Chỉ làm đúng một việc: dựng [HomeBloc] từ [HomeRepository] của composition root
/// rồi bắn ngay [FetchHomeData]. Toàn bộ UI nằm ở [HomeView] để việc dựng bloc và
/// việc render tách bạch, giúp [HomeView] test được với bloc giả.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        homeRepository: context.read<HomeRepository>(),
      )..add(FetchHomeData()),
      child: const HomeView(),
    );
  }
}
