import 'package:fe/presentation/medications/view/medication_view.dart';
import 'package:flutter/material.dart';

/// Tab Thuốc — [MedicationBloc] do ShellRoute trong `app_router` cung cấp.
class MedicationPage extends StatelessWidget {
  const MedicationPage({super.key});

  @override
  Widget build(BuildContext context) => const MedicationView();
}
