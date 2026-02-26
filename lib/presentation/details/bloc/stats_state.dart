part of 'stats_bloc.dart';

enum StatsStatus { initial, loading, loaded, error }
enum ChartStatus { initial, loading, loaded, error }

class StatsState extends Equatable {
  const StatsState({
    this.status = StatsStatus.initial,
    this.statsData,
    this.errorMessage,
    this.chartStatus = ChartStatus.initial, 
    this.chartData,
    this.chartErrorMessage,
  });

  final StatsStatus status;
  final StatsPageData? statsData;
  final String? errorMessage;
  final ChartStatus chartStatus;
  final List<MetricChart>? chartData;
  final String? chartErrorMessage;

  // Khởi tạo state ban đầu
  factory StatsState.initial() {
    return StatsState(
      status: StatsStatus.initial,
      statsData: StatsPageData.empty(),
      chartStatus: ChartStatus.initial,
    );
  }

  StatsState copyWith({
    StatsStatus? status,
    StatsPageData? statsData,
    String? errorMessage,
    ChartStatus? chartStatus,
    List<MetricChart>? chartData,
    String? chartErrorMessage,
  }) {
    return StatsState(
      status: status ?? this.status,
      statsData: statsData ?? this.statsData,
      errorMessage: errorMessage ?? this.errorMessage,
      chartStatus: chartStatus ?? this.chartStatus,
      chartData: chartData ?? this.chartData,
      chartErrorMessage: chartErrorMessage ?? this.chartErrorMessage,
    );
  }

  @override
  List<Object?> get props => [status, statsData, errorMessage,chartStatus, chartData, chartErrorMessage];
}