import 'models/post_encounter_document_kind.dart';

abstract final class PostEncounterWizardNavigation {
  static const queryKey = 'encounterWizard';

  static bool isEnabled(Map<String, String> queryParameters) =>
      queryParameters[queryKey] == '1';

  static String withWizardQuery(String path) {
    final uri = Uri.parse(path);
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            queryKey: '1',
          },
        )
        .toString();
  }

  static String buildDocumentFormPath({
    required PostEncounterDocumentKind kind,
    required String patientId,
    required String clinicalEncounterId,
  }) {
    final base = switch (kind) {
      PostEncounterDocumentKind.lab =>
        '/lab-orders/new?patientId=$patientId&clinicalEncounterId=$clinicalEncounterId',
      PostEncounterDocumentKind.radiology =>
        '/radiology-orders/new?patientId=$patientId&clinicalEncounterId=$clinicalEncounterId',
      PostEncounterDocumentKind.prescription =>
        '/prescriptions/new?patientId=$patientId&clinicalEncounterId=$clinicalEncounterId',
      PostEncounterDocumentKind.clinicalReport =>
        '/clinical-reports/new?patientId=$patientId&clinicalEncounterId=$clinicalEncounterId',
    };
    return withWizardQuery(base);
  }

  static String buildPaymentStepPath(String clinicalEncounterId) =>
      '/clinical-records/$clinicalEncounterId/wizard-payment';
}
