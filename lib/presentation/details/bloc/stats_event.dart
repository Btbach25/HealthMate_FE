part of 'stats_bloc.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object> get props => [];
}

/// Sự kiện được gọi khi màn hình Stats cần tải dữ liệu.
class FetchStatsData extends StatsEvent {}