part of 'stats_bloc.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object> get props => [];
}

/// Sự kiện được gọi khi màn hình Stats cần tải dữ liệu.
class FetchStatsData extends StatsEvent {}

class FetchChartData extends StatsEvent {}

/// Dùng data từ thiết bị khi BE không khả dụng.
class TryDeviceFallback extends StatsEvent {}

/// Đổi range thời gian (24h / 7d / 30d) → tự re-fetch.
class ChangeStatsRange extends StatsEvent {
  final String range;
  const ChangeStatsRange(this.range);

  @override
  List<Object> get props => [range];
}