import 'package:fe/data/repositories/medication_repository.dart';
import 'package:fe/presentation/medications/bloc/medication_bloc.dart';
import 'package:fe/presentation/medications/view/medication_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicationPage extends StatelessWidget {
  const MedicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MedicationBloc(
        repository: context.read<MedicationRepository>(),
      )..add(const FetchMedications()),
      child: const MedicationView(),
    );
  }
}
