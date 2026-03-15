import 'package:equatable/equatable.dart';
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
  }

  Future<void> _onFetch(
    FetchMedications event,
    Emitter<MedicationState> emit,
  ) async {
    emit(state.copyWith(status: MedicationStatus.loading));
    try {
      final meds = await _repository.getMedications();
      emit(state.copyWith(status: MedicationStatus.loaded, medications: meds));
    } catch (e) {
      emit(state.copyWith(
        status: MedicationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTake(
    TakeMedication event,
    Emitter<MedicationState> emit,
  ) async {
    // Optimistic update: toggle locally for instant UI response
    final original = state.medications;
    final optimistic =
        _toggleLocally(original, event.medicationId, event.reminderId);
    emit(state.copyWith(medications: optimistic));

    try {
      final confirmed = await _repository.takeMedication(
          event.medicationId, event.reminderId);
      emit(state.copyWith(medications: confirmed));
    } catch (e) {
      // Revert on error
      emit(state.copyWith(medications: original));
    }
  }

  Future<void> _onAdd(
    AddMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _repository.addMedication(event.medication);
      final meds = await _repository.getMedications();
      emit(state.copyWith(status: MedicationStatus.loaded, medications: meds));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
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
