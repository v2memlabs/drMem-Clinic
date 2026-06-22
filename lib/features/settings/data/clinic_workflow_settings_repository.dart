import '../models/clinic_workflow_settings.dart';

/// Klinik işleyiş ayarları — tenant-scoped persistence.
abstract interface class ClinicWorkflowSettingsRepository {
  Future<ClinicWorkflowSettings?> load();

  Future<void> save(ClinicWorkflowSettings settings);
}

class ClinicWorkflowSettingsRepositoryException implements Exception {
  const ClinicWorkflowSettingsRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
