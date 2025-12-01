part of 'health_overview_bloc.dart';

enum HealthOverviewStatus { initial, loading, success, failure }

class HealthOverviewState extends Equatable {
  final HealthOverviewStatus status;
  final HealthOverview? overview;
  final String? errorMessage;

  const HealthOverviewState({
    this.status = HealthOverviewStatus.initial,
    this.overview,
    this.errorMessage,
  });

  HealthOverviewState copyWith({
    HealthOverviewStatus? status,
    HealthOverview? overview,
    String? errorMessage,
  }) {
    return HealthOverviewState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, overview, errorMessage];
}
