import '../../settings/data/clinic_workflow_settings_mapper.dart';
import '../../settings/data/clinic_workflow_settings_repository_provider.dart';
import '../../settings/models/clinic_workflow_settings.dart';
import '../models/clinic_schedule_config.dart';
import 'clinic_schedule_config_source.dart';

/// Klinik işleyiş persistence → [ClinicScheduleConfig].
final class PersistedClinicScheduleConfigSource
    implements ClinicScheduleConfigSource {
  const PersistedClinicScheduleConfigSource();

  Future<ClinicWorkflowSettings> loadSettings() async {
    try {
      final loaded =
          await ClinicWorkflowSettingsRepositoryProvider.repository.load();
      return loaded ?? ClinicWorkflowSettings.defaultClinic();
    } catch (_) {
      return ClinicWorkflowSettings.defaultClinic();
    }
  }

  @override
  Future<ClinicScheduleConfig> loadForCurrentTenant() async {
    final settings = await loadSettings();
    return ClinicWorkflowSettingsMapper.toScheduleConfig(settings);
  }

  Future<ClinicScheduleConfig> loadForDay(DateTime day) async {
    final settings = await loadSettings();
    return ClinicWorkflowSettingsMapper.toScheduleConfigForDay(settings, day);
  }
}
