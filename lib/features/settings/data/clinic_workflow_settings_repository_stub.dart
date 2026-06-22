import '../models/clinic_workflow_settings.dart';
import 'clinic_workflow_settings_repository.dart';

class ClinicWorkflowSettingsRepositoryStub
    implements ClinicWorkflowSettingsRepository {
  const ClinicWorkflowSettingsRepositoryStub();

  Never _notConfigured() => throw const ClinicWorkflowSettingsRepositoryException(
        'Klinik işleyiş ayarları şu anda kullanıma hazır değil.',
      );

  @override
  Future<ClinicWorkflowSettings?> load() async => _notConfigured();

  @override
  Future<void> save(ClinicWorkflowSettings settings) async => _notConfigured();
}
