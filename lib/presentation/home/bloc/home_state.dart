part of 'home_bloc.dart';

/// `initial` và `loading` được [HomeView] render giống nhau (cùng một spinner).
enum HomeStatus { initial, loading, loaded, error }

/// [homeData] không bao giờ null sau [HomeState.initial], nhưng vẫn khai báo nullable
/// vì [copyWith] không phân biệt được "không truyền" với "đặt về null".
class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.homeData,
    this.errorMessage,
  });

  final HomeStatus status;
  final HomeData? homeData;
  final String? errorMessage;

  /// State khởi tạo.
  ///
  /// `homeData` được điền sẵn bằng [HomeData.empty] thay vì để null, nhờ đó widget nào
  /// đọc `state.homeData!` trước khi tải xong cũng không nổ null-check.
  factory HomeState.initial() {
    return HomeState(
      status: HomeStatus.initial,
      homeData: HomeData.empty(),
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
