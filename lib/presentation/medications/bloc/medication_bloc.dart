import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/repositories/medication_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'medication_event.dart';
part 'medication_state.dart';

class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final MedicationRepository _repository;

  MedicationBloc({required MedicationRepository repository})
      : _repository = repository,
        super(const MedicationState()) {
    on<FetchMedications>(_onFetch);
    on<TakeMedication>(_onTake);
    on<AddMedication>(_onAdd);
    on<AddMedicationsBatch>(_onAddBatch);
    on<DeleteMedication>(_onDelete);
    on<ClearMedicationFeedback>(_onClearFeedback);
  }

  Future<void> _onClearFeedback(
    ClearMedicationFeedback event,
    Emitter<MedicationState> emit,
  ) async {
    emit(state.copyWith(clearFeedback: true));
  }

  Future<void> _onFetch(
    FetchMedications event,
    Emitter<MedicationState> emit,
  ) async {
    emit(state.copyWith(
      status: MedicationStatus.loading,
      clearFeedback: true,
    ));
    try {
      final meds = await _repository.getMedications();
      emit(state.copyWith(status: MedicationStatus.loaded, medications: meds));
    } catch (e) {
      emit(state.copyWith(
        status: MedicationStatus.error,
        errorMessage: UserFacingError.message(e),
      ));
    }
  }

  Future<void> _onTake(
    TakeMedication event,
    Emitter<MedicationState> emit,
  ) async {
    final original = state.medications;
    final optimistic =
        _toggleLocally(original, event.medicationId, event.reminderId);
    emit(state.copyWith(
      medications: optimistic,
      clearFeedback: true,
    ));

    try {
      final confirmed = await _repository.takeMedication(
          event.medicationId, event.reminderId);
      emit(state.copyWith(medications: confirmed, clearFeedback: true));
    } catch (e) {
      emit(state.copyWith(
        medications: original,
        feedbackMessage: UserFacingError.message(e),
        feedbackIsError: true,
      ));
    }
  }

  Future<void> _onAdd(
    AddMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _repository.addMedication(event.medication);
      final meds = await _repository.getMedications();
      emit(state.copyWith(
        status: MedicationStatus.loaded,
        medications: meds,
        clearErrorMessage: true,
        feedbackMessage: 'Đã thêm thuốc vào lịch',
        feedbackIsError: false,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: UserFacingError.message(e)));
    }
  }

  Future<void> _onAddBatch(
    AddMedicationsBatch event,
    Emitter<MedicationState> emit,
  ) async {
    if (event.medications.isEmpty) return;
    final n = event.medications.length;
    try {
      for (final m in event.medications) {
        await _repository.addMedication(m);
      }
      final meds = await _repository.getMedications();
      emit(state.copyWith(
        status: MedicationStatus.loaded,
        medications: meds,
        clearErrorMessage: true,
        feedbackMessage: 'Đã thêm $n thuốc vào lịch',
        feedbackIsError: false,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: UserFacingError.message(e)));
    }
  }

  Future<void> _onDelete(
    DeleteMedication event,
    Emitter<MedicationState> emit,
  ) async {
    emit(state.copyWith(
      deletingMedicationId: event.medicationId,
      clearFeedback: true,
    ));
    try {
      await _repository.deleteMedication(event.medicationId);
      final meds = await _repository.getMedications();
      emit(state.copyWith(
        status: MedicationStatus.loaded,
        medications: meds,
        clearErrorMessage: true,
        clearDeletingMedicationId: true,
        feedbackMessage: 'Đã xóa thuốc khỏi lịch',
        feedbackIsError: false,
      ));
    } on NotFoundException {
      // 404: bản ghi không còn (hoặc route sai — sau khi sửa gateway vẫn an toàn làm mới list)
      try {
        final meds = await _repository.getMedications();
        emit(state.copyWith(
          status: MedicationStatus.loaded,
          medications: meds,
          clearDeletingMedicationId: true,
          feedbackMessage:
              'Không tìm thấy thuốc trên máy chủ. Danh sách đã được làm mới.',
          feedbackIsError: false,
        ));
      } catch (e) {
        emit(state.copyWith(
          clearDeletingMedicationId: true,
          feedbackMessage: UserFacingError.message(e),
          feedbackIsError: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        clearDeletingMedicationId: true,
        feedbackMessage: UserFacingError.message(e),
        feedbackIsError: true,
      ));
    }
  }

  List<Medication> _toggleLocally(
    List<Medication> meds,
    String medicationId,
    String reminderId,
  ) {
    return meds.map((med) {
      if (med.id != medicationId) return med;
      final updatedReminders = med.reminders.map((r) {
        if (r.id != reminderId) return r;
        return r.isTakenToday
            ? r.copyWith(clearLastTaken: true)
            : r.copyWith(lastTaken: DateTime.now());
      }).toList();
      return med.copyWith(reminders: updatedReminders);
    }).toList();
  }
}
