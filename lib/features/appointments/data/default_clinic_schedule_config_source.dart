import '../models/clinic_schedule_config.dart';
import 'clinic_schedule_config_source.dart';

/// v1 — sabit varsayılan mesai (tenant/settings bağlı değil).
final class DefaultClinicScheduleConfigSource
    implements ClinicScheduleConfigSource {
  const DefaultClinicScheduleConfigSource();

  @override
  Future<ClinicScheduleConfig> loadForCurrentTenant() async {
    return ClinicScheduleConfig.defaultClinic();
  }
}
