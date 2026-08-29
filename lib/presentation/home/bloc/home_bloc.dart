import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/data/models/home_data.dart';
import 'package:fe/data/repositories/home_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Quản lý dữ liệu tổng hợp của màn hình Home (user, tiến độ uống thuốc, thông báo
/// gia đình) — tức mọi thứ *không* đến từ thiết bị đeo.
///
/// Máy trạng thái rất phẳng, chỉ có một event:
///
///   initial --FetchHomeData--> loading --+-- repo trả về ----> loaded (state.homeData != null)
///                                        +-- repo ném lỗi ---> error  (state.errorMessage)
///
/// Ai bắn event:
/// - [HomePage] bắn [FetchHomeData] ngay khi dựng bloc.
/// - [HomeView] bắn lại khi người dùng kéo RefreshIndicator, hoặc bấm "Thử lại"
///   ở màn hình lỗi.
///
/// Cạm bẫy: `HomeState.copyWith` không đặt được `errorMessage` về null, nên khi
/// chuyển error -> loading thông điệp lỗi cũ vẫn nằm trong state. Hiện vô hại vì UI
/// chỉ đọc nó khi `status == HomeStatus.error`.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;

  HomeBloc({required HomeRepository homeRepository})
      : _homeRepository = homeRepository,
        super(HomeState.initial()) {
    on<FetchHomeData>(_onFetchHomeData);
  }

  Future<void> _onFetchHomeData(
    FetchHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final homeData = await _homeRepository.getHomeData();

      emit(state.copyWith(
        status: HomeStatus.loaded,
        homeData: homeData,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: UserFacingError.message(e),
      ));
    }
  }
}