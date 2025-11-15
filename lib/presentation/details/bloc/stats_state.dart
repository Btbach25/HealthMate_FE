part of 'stats_bloc.dart';

enum StatsStatus { initial, loading, loaded, error }

class StatsState extends Equatable {
  const StatsState({
    this.status = StatsStatus.initial,
    this.statsData,
    this.errorMessage,
  });

  final StatsStatus status;
  final StatsPageData? statsData;
  final String? errorMessage;

  // Khởi tạo state ban đầu
  factory StatsState.initial() {
    return StatsState(
      status: StatsStatus.initial,
      statsData: StatsPageData.empty(),
    );
  }

  StatsState copyWith({
    StatsStatus? status,
    StatsPageData? statsData,
    String? errorMessage,
  }) {
    return StatsState(
      status: status ?? this.status,
      statsData: statsData ?? this.statsData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, statsData, errorMessage];
}