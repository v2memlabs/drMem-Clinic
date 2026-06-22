import '../models/clinic_schedule_config.dart';

/// İleride Klinik İşleyiş persistence bu arayüzü besleyecek.
abstract interface class ClinicScheduleConfigSource {
  Future<ClinicScheduleConfig> loadForCurrentTenant();
}
