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

/// Patch một hoặc nhiều chỉ số sau khi user nhập tay — luôn ghi đè bất kể nguồn.
class HealthOverviewManualPatched extends HealthOverviewEvent {
  final HeartRate? heartRate;
  final BloodPressure? bloodPressure;
  const HealthOverviewManualPatched({this.heartRate, this.bloodPressure});
  @override
  List<Object?> get props => [heartRate, bloodPressure];
}
