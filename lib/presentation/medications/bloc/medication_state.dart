part of 'medication_bloc.dart';

enum MedicationStatus { initial, loading, loaded, error }

class MedicationState extends Equatable {
  final MedicationStatus status;
  final List<Medication> medications;
  final String? errorMessage;

  /// Snackbar một lần (thành công / lỗi nhẹ), không thay thế [errorMessage] khi tải lỗi toàn trang.
  final String? feedbackMessage;
  final bool feedbackIsError;

  /// Đang xóa thuốc (id) — hiển thị loading trên dòng tương ứng.
  final String? deletingMedicationId;

  const MedicationState({
    this.status = MedicationStatus.initial,
    this.medications = const [],
    this.errorMessage,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.deletingMedicationId,
  });

  MedicationState copyWith({
    MedicationStatus? status,
    List<Medication>? medications,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
    String? deletingMedicationId,
    bool clearDeletingMedicationId = false,
  }) =>
      MedicationState(
        status: status ?? this.status,
        medications: medications ?? this.medications,
        errorMessage:
            clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
        feedbackMessage:
            clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
        feedbackIsError: clearFeedback
            ? false
            : (feedbackIsError ?? this.feedbackIsError),
        deletingMedicationId: clearDeletingMedicationId
            ? null
            : (deletingMedicationId ?? this.deletingMedicationId),
      );

  @override
  List<Object?> get props => [
        status,
        medications,
        errorMessage,
        feedbackMessage,
        feedbackIsError,
        deletingMedicationId,
      ];
}
