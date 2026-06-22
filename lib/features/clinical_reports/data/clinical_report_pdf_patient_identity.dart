import '../../patients/models/patient.dart';
import '../../pdf_outputs/data/clinical_pdf_patient_identity.dart';

/// Geriye dönük uyumluluk — yeni kod `ClinicalPdfPatientIdentity` kullanmalı.
abstract final class ClinicalReportPdfPatientIdentity {
  static String? turkishNationalIdForPdf(Patient? patient) =>
      ClinicalPdfPatientIdentity.turkishNationalIdForPdf(patient);
}
