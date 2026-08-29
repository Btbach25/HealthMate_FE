part of 'stats_bloc.dart';

/// Base class cho mọi event của [StatsBloc].
abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object> get props => [];
}

/// Tải lại toàn bộ số liệu của màn Chỉ số (metric list + header).
///
/// Ai bắn: `StatsPage` ngay khi tạo bloc, nút "Thử lại" ở màn lỗi, và
/// `RefreshIndicator` khi người dùng kéo xuống.
class FetchStatsData extends StatsEvent {}

/// Tải dữ liệu biểu đồ — tách riêng vì tab "Biểu đồ" là lazy: chỉ fetch lần
/// đầu người dùng mở tab đó (xem `StatsChartLazyLoader`).
class FetchChartData extends StatsEvent {}

/// Thử lấp số liệu bằng dữ liệu đo từ điện thoại khi BE không có dữ liệu.
///
/// Ai bắn: `StatsView` — một lần sau frame đầu tiên, và mỗi khi
/// `DeviceHealthCubit` thu thêm điểm đo mới. Bloc tự bỏ qua nếu đã có dữ liệu
/// thật từ server, nên bắn thừa là vô hại.
class TryDeviceFallback extends StatsEvent {}

/// Đổi khoảng thời gian (24h / 7d / 30d) — bloc tự fetch lại ngay.
///
/// Ai bắn: menu chọn range trên header của `StatsView`.
class ChangeStatsRange extends StatsEvent {
  final String range;
  const ChangeStatsRange(this.range);

  @override
  List<Object> get props => [range];
}
