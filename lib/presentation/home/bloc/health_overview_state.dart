part of 'health_overview_bloc.dart';

/// `failure` chỉ xuất hiện khi backend lỗi *và* cũng chưa có dữ liệu thiết bị nào —
/// còn lại luôn ưu tiên `success` với dữ liệu sẵn có.
enum HealthOverviewStatus { initial, loading, success, failure }

/// [overview] null nghĩa là chưa có bất kỳ nguồn nào trả dữ liệu.
///
/// Như mọi copyWith trong dự án này, [overview] và [errorMessage] không đặt lại về
/// null được; thông điệp lỗi cũ sẽ còn lại sau khi chuyển về `success`.
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
