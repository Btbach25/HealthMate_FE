import 'package:fe/data/models/home_data.dart';

abstract class HomeService {
  Future<HomeData> getHomeData();
}