part of 'health_overview_bloc.dart';

abstract class HealthOverviewEvent extends Equatable {
  const HealthOverviewEvent();
  @override
  List<Object?> get props => [];
}

class HealthOverviewRequested extends HealthOverviewEvent {
  const HealthOverviewRequested();
}

class HealthOverviewRetried extends HealthOverviewEvent {
  const HealthOverviewRetried();
}

class HealthOverviewDeviceLoaded extends HealthOverviewEvent {
  final HealthOverview overview;
  const HealthOverviewDeviceLoaded(this.overview);
  @override
  List<Object?> get props => [overview];
}
