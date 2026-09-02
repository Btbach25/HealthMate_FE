import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Gom quy tắc "trạng thái nào thì phải tải lại dữ liệu" của một bloc vào một
/// chỗ, để `BlocListener` ở màn hình chỉ còn một dòng gọi.
///
/// Dùng cho màn hình cần refresh sau các thao tác ghi (tạo nhóm, mời thành
/// viên, rời nhóm…): liệt kê các status "vừa xong việc" vào
/// [refreshTriggerStates] rồi để helper quyết định.
///
/// Khai báo helper là `static final` của widget để giữ nguyên qua các lần
/// rebuild:
///
/// ```dart
/// static final _refreshHelper = BlocRefreshHelper<FamilyBloc, FamilyState>(
///   initialState: FamilyStatus.initial,
///   refreshTriggerStates: {FamilyStatus.groupCreated, FamilyStatus.groupLeft},
///   onRefresh: (context, bloc) => bloc.add(const LoadFamilySummary()),
/// );
/// ```
///
/// Mặc định helper đọc `state.status` bằng dynamic (không có kiểu chung cho
/// mọi state), nên state PHẢI có trường `status` — hoặc truyền
/// [statusExtractor] để chỉ rõ cách lấy.
class BlocRefreshHelper<B extends StateStreamable<S>, S> {
  final Set<dynamic> refreshTriggerStates;
  final void Function(BuildContext, B) onRefresh;
  final dynamic initialState;
  final dynamic Function(S)? statusExtractor;

  const BlocRefreshHelper({
    required this.refreshTriggerStates,
    required this.onRefresh,
    required this.initialState,
    this.statusExtractor,
  });

  /// `true` nếu status hiện tại nằm trong [refreshTriggerStates].
  bool shouldRefresh(S currentState) {
    final status =
        statusExtractor?.call(currentState) ?? (currentState as dynamic).status;
    return refreshTriggerStates.contains(status);
  }

  /// `true` nếu bloc còn ở [initialState] (chưa từng tải dữ liệu).
  bool isInitialState(S currentState) {
    final status =
        statusExtractor?.call(currentState) ?? (currentState as dynamic).status;
    return status == initialState;
  }

  /// Gọi từ `BlocListener.listener`; trả `true` nếu đã bắn refresh.
  ///
  /// [hasInitialized] CỐ Ý không được xét ở đây: cờ đó chỉ để chặn gọi
  /// [fetchInitialDataIfNeeded] nhiều lần, chứ không được phép chặn refresh
  /// sau một thao tác ghi.
  bool handleStateChange(BuildContext context, S state, bool hasInitialized) {
    if (!shouldRefresh(state)) return false;

    final bloc = context.read<B>();
    onRefresh(context, bloc);
    return true;
  }

  /// Tải dữ liệu lần đầu nếu bloc còn ở [initialState].
  /// Trả `true` nếu đã bắn event tải.
  bool fetchInitialDataIfNeeded(BuildContext context, S currentState) {
    if (!isInitialState(currentState)) return false;

    final bloc = context.read<B>();
    onRefresh(context, bloc);
    return true;
  }
}
