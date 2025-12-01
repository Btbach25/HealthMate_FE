// ignore_for_file: avoid_print

import 'package:fe/data/models/home_data.dart';

import 'package:fe/data/services/home_service.dart';

class HomeRepository {
  final HomeService _homeService;

  HomeRepository({required HomeService homeService})
      : _homeService = homeService;

  Future<HomeData> getHomeData() async {
    try {
      final homeData = await _homeService.getHomeData();
      return homeData;
    } catch (e) {
      print('Error in HomeRepository.getHomeData: $e');
      rethrow;
    }
  }
}