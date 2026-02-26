part of 'home_bloc.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.homeData,
    this.errorMessage,
  });

  final HomeStatus status;
  final HomeData? homeData;
  final String? errorMessage;

  // Khởi tạo state ban đầu
  factory HomeState.initial() {
    return HomeState(
      status: HomeStatus.initial,
      homeData: HomeData.empty(), // Sử dụng factory empty()
    );
  }

  HomeState copyWith({
    HomeStatus? status,
    HomeData? homeData,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      homeData: homeData ?? this.homeData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, homeData, errorMessage];
}