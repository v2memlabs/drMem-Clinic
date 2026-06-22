import '../../../core/auth/auth_session.dart';
import '../../clinical_encounter/data/clinical_encounter_patient_detail_data_source.dart';
import '../../clinical_encounter/models/clinical_encounter.dart';
import '../../patient_files/data/patient_file_metadata_module_availability.dart';

/// Hasta detay aksiyonları — kart görünürlüğü ve prefill bağlamı.
class PatientDetailActionContext {
  final String patientId;
  final String? latestClinicalEncounterId;
  final bool showsFilePreviewCard;
  final bool showsRehabPreviewCard;
  final bool showsAssistantSummaryCard;

  const PatientDetailActionContext({
    required this.patientId,
    this.latestClinicalEncounterId,
    this.showsFilePreviewCard = false,
    this.showsRehabPreviewCard = false,
    this.showsAssistantSummaryCard = false,
  });

  String get patientQuery => '?patientId=$patientId';

  factory PatientDetailActionContext.fromView({
    required String patientId,
    List<ClinicalEncounter>? clinicalEncounters,
    required bool showsAssistantClinical,
  }) {
    final latest = clinicalEncounters == null
        ? null
        : ClinicalEncounterPatientDetailDataSource.latest(clinicalEncounters);
    final showsFile = AuthSession.canViewFiles &&
        PatientFileMetadataModuleAvailability.isOperational;

    return PatientDetailActionContext(
      patientId: patientId,
      latestClinicalEncounterId: latest?.id,
      showsFilePreviewCard: showsFile,
      showsRehabPreviewCard: AuthSession.canViewClinicalEncounters,
      showsAssistantSummaryCard: showsAssistantClinical,
    );
  }
}
