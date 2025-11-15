import 'package:fe/data/models/details/stats_page_data.dart';

abstract class StatsService {
  Future<StatsPageData> getStatsPageData();
}