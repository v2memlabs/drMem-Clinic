import '../../../core/data/repository_registry.dart';
import '../../settings/data/clinic_workflow_settings_mapper.dart';
import '../../settings/data/clinic_workflow_settings_repository_provider.dart';
import '../../settings/data/staff_leave_record_repository_provider.dart';
import '../../settings/models/clinic_workflow_settings.dart';
import 'staff_leave_availability_helper.dart';
import '../models/appointment.dart';
import '../models/appointment_slot.dart';
import '../models/clinic_schedule_config.dart';
import 'appointment_availability_service.dart';
import 'clinic_schedule_config_source.dart';
import 'default_clinic_schedule_config_source.dart';
import 'persisted_clinic_schedule_config_source.dart';

/// Gün bazlı randevu listesi + slot üretimi.
///
/// Aktif personel izin kayıtları ([staff_leave_records]) çakışan randevu slotlarını kapatır.
abstract final class AppointmentAvailabilityDataSource {
  static ClinicScheduleConfigSource scheduleConfigSource =
      const PersistedClinicScheduleConfigSource();

  static Future<ClinicWorkflowSettings> _loadWorkflowSettings() async {
    final loaded =
        await ClinicWorkflowSettingsRepositoryProvider.repository.load();
    return loaded ?? ClinicWorkflowSettings.defaultClinic();
  }

  static Future<ClinicScheduleConfig> _configForDay(DateTime day) async {
    final source = scheduleConfigSource;
    if (source is PersistedClinicScheduleConfigSource) {
      return source.loadForDay(day);
    }
    final settings = await _loadWorkflowSettings();
    return ClinicWorkflowSettingsMapper.toScheduleConfigForDay(settings, day);
  }

  static Future<AppointmentAvailabilityResult> loadSlotsForDay({
    required DateTime day,
    String? excludeAppointmentId,
    DateTime? selectedSlotStart,
    DateTime? preserveCurrentSlotStart,
    int? preserveCurrentDurationMinutes,
    bool isEditMode = false,
  }) async {
    final config = await _configForDay(day);
    final calendarDay = DateTime(day.year, day.month, day.day);
    final appointments =
        await RepositoryRegistry.appointmentsAsync.getForCalendarDay(calendarDay);

    var staffLeaveBlocks = const <StaffLeaveBusyBlock>[];
    try {
      final leaves = await StaffLeaveRecordRepositoryProvider.repository
          .listActiveForCalendarDay(calendarDay);
      staffLeaveBlocks = StaffLeaveAvailabilityHelper.blocksForDay(
        calendarDay: calendarDay,
        leaves: leaves,
      );
    } catch (_) {
      // İzin kayıtları yüklenemezse slotlar yalnızca randevu çakışmasına göre üretilir.
    }

    return AppointmentAvailabilityService.buildSlots(
      day: calendarDay,
      config: config,
      existingAppointments: appointments,
      staffLeaveBlocks: staffLeaveBlocks,
      excludeAppointmentId: excludeAppointmentId,
      selectedSlotStart: selectedSlotStart,
      preserveCurrentSlotStart: preserveCurrentSlotStart,
      preserveCurrentDurationMinutes: preserveCurrentDurationMinutes,
      allowPastSlots: isEditMode,
    );
  }

  static Future<ClinicScheduleConfig> loadScheduleConfig() =>
      scheduleConfigSource.loadForCurrentTenant();
}
