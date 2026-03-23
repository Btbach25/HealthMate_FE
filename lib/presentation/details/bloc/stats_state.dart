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
    this.selectedRange = '7d',
    this.isFromDevice = false,
  });

  final StatsStatus status;
  final StatsPageData? statsData;
  final String? errorMessage;
  final ChartStatus chartStatus;
  final List<MetricChart>? chartData;
  final String? chartErrorMessage;
  final String selectedRange;
  final bool isFromDevice;

  static const List<String> availableRanges = ['24h', '7d', '30d'];

  factory StatsState.initial() {
    return const StatsState(
      status: StatsStatus.initial,
      chartStatus: ChartStatus.initial,
      selectedRange: '7d',
    );
  }

  StatsState copyWith({
    StatsStatus? status,
    StatsPageData? statsData,
    String? errorMessage,
    ChartStatus? chartStatus,
    List<MetricChart>? chartData,
    String? chartErrorMessage,
    String? selectedRange,
    bool? isFromDevice,
  }) {
    return StatsState(
      status: status ?? this.status,
      statsData: statsData ?? this.statsData,
      errorMessage: errorMessage ?? this.errorMessage,
      chartStatus: chartStatus ?? this.chartStatus,
      chartData: chartData ?? this.chartData,
      chartErrorMessage: chartErrorMessage ?? this.chartErrorMessage,
      selectedRange: selectedRange ?? this.selectedRange,
      isFromDevice: isFromDevice ?? this.isFromDevice,
    );
  }

  @override
  List<Object?> get props => [status, statsData, errorMessage, chartStatus, chartData, chartErrorMessage, selectedRange, isFromDevice];
}