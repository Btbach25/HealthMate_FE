part of 'medication_bloc.dart';

enum MedicationStatus { initial, loading, loaded, error }

class MedicationState extends Equatable {
  final MedicationStatus status;
  final List<Medication> medications;
  final String? errorMessage;

  const MedicationState({
    this.status = MedicationStatus.initial,
    this.medications = const [],
    this.errorMessage,
  });

  MedicationState copyWith({
    MedicationStatus? status,
    List<Medication>? medications,
    String? errorMessage,
  }) =>
      MedicationState(
        status: status ?? this.status,
        medications: medications ?? this.medications,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, medications, errorMessage];
}
