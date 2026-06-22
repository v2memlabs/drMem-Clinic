import '../../../core/data/repository_registry.dart';
import 'first_visit_consent_checklist.dart';

/// Hasta için zorunlu ilk ziyaret onamlarını değerlendirir.
abstract final class FirstVisitConsentGate {
  static Future<FirstVisitConsentChecklist> loadChecklist(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) {
      return FirstVisitConsentChecklist.evaluate(
        patientId: pid,
        consents: const [],
      );
    }

    final consents = await RepositoryRegistry.consentsAsync.getByPatientId(pid);
    return FirstVisitConsentChecklist.evaluate(
      patientId: pid,
      consents: consents,
    );
  }

  static Future<bool> isComplete(String patientId) async {
    final checklist = await loadChecklist(patientId);
    return checklist.isComplete;
  }
}
