/// Oturum içinde "Devam et" ile kapatılan hasta onam uyarıları.
abstract final class ConsentGateSessionStore {
  static final Set<String> _dismissedPatientIds = {};

  static bool isDismissed(String patientId) =>
      _dismissedPatientIds.contains(patientId.trim());

  static void dismiss(String patientId) {
    final id = patientId.trim();
    if (id.isEmpty) return;
    _dismissedPatientIds.add(id);
  }

  static void clearDismiss(String patientId) {
    _dismissedPatientIds.remove(patientId.trim());
  }

  static void clearAll() => _dismissedPatientIds.clear();
}
