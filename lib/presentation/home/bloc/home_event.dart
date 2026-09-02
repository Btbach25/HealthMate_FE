part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

/// Sự kiện được gọi khi màn hình Home cần tải dữ liệu.
class FetchHomeData extends HomeEvent {}
