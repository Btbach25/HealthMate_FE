import 'package:fe/data/models/home_data.dart';
import 'package:fe/presentation/home/widgets/stat_config.dart';
import 'package:flutter/material.dart';
import 'stat_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/health_overview_bloc.dart';
import 'package:fe/data/models/health/health_overview.dart';

class StatsGrid extends StatelessWidget {
  final HomeData homeData;
  const StatsGrid({super.key, required this.homeData});

  @override
  Widget build(BuildContext context) {
    const horizontalSpacing = SizedBox(width: 16);
    const verticalSpacing = SizedBox(height: 16);

    final cardChunks = [
      defaultStatCardsConfig.sublist(0, 2),
      defaultStatCardsConfig.sublist(2, defaultStatCardsConfig.length),
    ];

    // Read health overview from bloc; fallback to empty to keep layout
    final overview = context.watch<HealthOverviewBloc>().state.overview ?? HealthOverview.empty();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < cardChunks.length; i++) ...[
          if (i != 0) verticalSpacing,
          Row(
            children: [
              for (int j = 0; j < cardChunks[i].length; j++) ...[
                Expanded(
                  child: StatCard(
                    icon: cardChunks[i][j].icon,
                    iconColor: cardChunks[i][j].iconColor,
                    iconBgColor: cardChunks[i][j].iconBgColor,
                    title: cardChunks[i][j].title,
                    value: cardChunks[i][j].getValue(overview),
                    unit: cardChunks[i][j].unit,
                  ),
                ),
                if (j != cardChunks[i].length - 1) horizontalSpacing
              ]
            ],
          )
        ]
      ],
    );
  }
}

//////////////////////????????????????????
//// Chú thích: Chưa chỉnh 