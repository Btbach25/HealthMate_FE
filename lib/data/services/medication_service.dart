import '../models/medication/medication.dart';

abstract class MedicationService {
  Future<List<Medication>> getMedications();
  Future<Medication> addMedication(Medication medication);

  /// Toggle taken status for a specific reminder. Returns updated list.
  Future<List<Medication>> takeMedication(
      String medicationId, String reminderId);
}
