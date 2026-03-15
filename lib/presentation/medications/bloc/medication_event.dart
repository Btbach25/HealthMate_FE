part of 'medication_bloc.dart';

abstract class MedicationEvent extends Equatable {
  const MedicationEvent();

  @override
  List<Object> get props => [];
}

class FetchMedications extends MedicationEvent {
  const FetchMedications();
}

class TakeMedication extends MedicationEvent {
  final String medicationId;
  final String reminderId;

  const TakeMedication({
    required this.medicationId,
    required this.reminderId,
  });

  @override
  List<Object> get props => [medicationId, reminderId];
}

class AddMedication extends MedicationEvent {
  final Medication medication;

  const AddMedication({required this.medication});

  @override
  List<Object> get props => [medication];
}
