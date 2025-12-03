import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/view/family_group_management_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FamilyGroupManagementPage extends StatelessWidget {
  const FamilyGroupManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<FamilyBloc>(),
      child: const FamilyGroupManagementView(),
    );
  }
}


