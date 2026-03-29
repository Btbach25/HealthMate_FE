import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/data/models/health/health_overview.dart';
import 'package:fe/data/repositories/health_repository.dart';

part 'health_overview_event.dart';
part 'health_overview_state.dart';

class HealthOverviewBloc extends Bloc<HealthOverviewEvent, HealthOverviewState> {
  final HealthRepository _repository;
  HealthOverviewBloc({required HealthRepository repository})
      : _repository = repository,
        super(const HealthOverviewState()) {
    on<HealthOverviewRequested>(_onRequested);
    on<HealthOverviewRetried>(_onRetried);
  }

  Future<void> _onRequested(HealthOverviewRequested event, Emitter<HealthOverviewState> emit) async {
    emit(state.copyWith(status: HealthOverviewStatus.loading));
    try {
      final overview = await _repository.getOverview();
      emit(state.copyWith(status: HealthOverviewStatus.success, overview: overview));
    } catch (e) {
      emit(state.copyWith(
        status: HealthOverviewStatus.failure,
        errorMessage: UserFacingError.message(e),
      ));
    }
  }

  Future<void> _onRetried(HealthOverviewRetried event, Emitter<HealthOverviewState> emit) async {
    add(const HealthOverviewRequested());
  }

}
