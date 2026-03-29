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

/// Thêm nhiều thuốc sau khi người dùng xác nhận kế hoạch từ quét đơn.
class AddMedicationsBatch extends MedicationEvent {
  final List<Medication> medications;

  const AddMedicationsBatch({required this.medications});

  @override
  List<Object> get props => [medications];
}

class DeleteMedication extends MedicationEvent {
  final String medicationId;

  const DeleteMedication({required this.medicationId});

  @override
  List<Object> get props => [medicationId];
}

/// Xóa snackbar/feedback một lần sau khi UI đã hiển thị.
class ClearMedicationFeedback extends MedicationEvent {
  const ClearMedicationFeedback();
}
