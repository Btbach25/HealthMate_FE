part of 'medication_bloc.dart';

/// Sự kiện của [MedicationBloc]. Xem doc của bloc để biết luồng tổng thể.
abstract class MedicationEvent extends Equatable {
  const MedicationEvent();

  @override
  List<Object> get props => [];
}

/// Nạp lại toàn bộ danh sách thuốc từ server.
///
/// Bắn khi vào tab Thuốc, khi kéo để làm mới, và sau khi dialog quét đơn đóng.
class FetchMedications extends MedicationEvent {
  const FetchMedications();
}

/// Đánh dấu đã uống một lần nhắc — bắn lần nữa cùng tham số thì bỏ đánh dấu.
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

/// Thêm một thuốc do người dùng tự nhập.
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

/// Xoá một thuốc khỏi lịch.
///
/// Bloc xử lý riêng lỗi 404 (bản ghi đã bị xoá ở nơi khác): coi như thành công
/// và nạp lại danh sách thay vì báo lỗi cho người dùng.
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
