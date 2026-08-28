/// Một điểm dữ liệu trên biểu đồ chỉ số.
/// Ánh xạ từ một phần tử `data[]` của `GET /metrics/charts`
/// (`timestamp` -> [time], `value` -> [value]).
class ChartDataPoint {
  final DateTime time;
  final double value;

  ChartDataPoint({required this.time, required this.value});
}