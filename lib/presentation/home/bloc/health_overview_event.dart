part of 'health_overview_bloc.dart';

abstract class HealthOverviewEvent extends Equatable {
  const HealthOverviewEvent();
  @override
  List<Object?> get props => [];
}

/// Nạp chỉ số từ backend. [HealthOverviewSection] bắn khi màn hình xuất hiện.
class HealthOverviewRequested extends HealthOverviewEvent {
  const HealthOverviewRequested();
}

/// Người dùng bấm "Thử lại" ở banner lỗi; chỉ chuyển tiếp thành
/// [HealthOverviewRequested], tồn tại riêng để phân biệt trong log/analytics.
class HealthOverviewRetried extends HealthOverviewEvent {
  const HealthOverviewRetried();
}

/// Bloc tự bắn khi [DeviceHealthCubit] có số liệu mới. Chỉ được dùng làm nguồn dự
/// phòng: bị bỏ qua nếu overview hiện tại đã đến từ backend.
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
