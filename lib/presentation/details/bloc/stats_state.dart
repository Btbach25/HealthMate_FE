part of 'stats_bloc.dart';

/// Trạng thái tải phần số liệu chính. `loaded` là state terminal duy nhất mà
/// [StatsBloc] hiện phát ra sau khi fetch (lỗi được nuốt và chuyển sang dữ liệu
/// thiết bị hoặc `StatsPageData.empty()`).
enum StatsStatus { initial, loading, loaded, error }

/// Trạng thái tải riêng cho tab Biểu đồ. Giữ `initial` cho tới khi người dùng
/// mở tab lần đầu — đó chính là tín hiệu để `StatsChartLazyLoader` fetch.
enum ChartStatus { initial, loading, loaded, error }

/// State của màn Chỉ số sức khỏe.
///
/// Hai vùng dữ liệu tải độc lập nhau: [status] + [statsData] cho danh sách chỉ
/// số, [chartStatus] + [chartData] cho tab biểu đồ.
///
/// Cạm bẫy: [copyWith] dùng `??` nên KHÔNG thể set một field về `null`. Muốn
/// xoá [chartData] phải đưa [chartStatus] về `ChartStatus.initial` để lazy
/// loader fetch lại, chứ truyền `chartData: null` sẽ không có tác dụng.
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

  /// Khoảng thời gian đang xem. Giá trị hợp lệ nằm trong [availableRanges] và
  /// được gửi thẳng cho BE dưới dạng chuỗi.
  final String selectedRange;

  /// `true` khi số liệu đang hiển thị được suy ra từ cảm biến điện thoại thay
  /// vì từ server — `StatsView` dựa vào cờ này để hiện badge "Thiết bị".
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
  List<Object?> get props => [
    status,
    statsData,
    errorMessage,
    chartStatus,
    chartData,
    chartErrorMessage,
    selectedRange,
    isFromDevice,
  ];
}
