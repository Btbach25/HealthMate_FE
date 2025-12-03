import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:fe/presentation/family/view/group_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupDetailsPage extends StatelessWidget {
  final String groupId;

  const GroupDetailsPage({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<FamilyBloc>(),
      child: GroupDetailsView(groupId: groupId),
    );
  }
}

