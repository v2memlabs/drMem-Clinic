import '../../patients/models/patient.dart';

abstract final class ClinicalPdfPatientIdentity {
  /// PDF'de tam kimlik numarası — yalnızca T.C. Kimlik No tipinde.
  static String? turkishNationalIdForPdf(Patient? patient) {
    if (patient == null) return null;
    if (patient.identityType.trim() != Patient.defaultIdentityType) {
      return null;
    }
    final value = patient.identityNumber.trim();
    return value.isEmpty ? null : value;
  }
}
