import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/persisted_clinic_schedule_config_source.dart';
import 'package:v2mem_clinic/features/appointments/models/clinic_schedule_config.dart';
import 'package:v2mem_clinic/features/settings/data/clinic_workflow_settings_mapper.dart';
import 'package:v2mem_clinic/features/settings/data/clinic_workflow_settings_repository.dart';
import 'package:v2mem_clinic/features/settings/data/clinic_workflow_settings_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/models/clinic_workflow_settings.dart';

class _FakeWorkflowRepo implements ClinicWorkflowSettingsRepository {
  _FakeWorkflowRepo({this.stored});

  ClinicWorkflowSettings? stored;
  int loadCount = 0;

  @override
  Future<ClinicWorkflowSettings?> load() async {
    loadCount++;
    return stored;
  }

  @override
  Future<void> save(ClinicWorkflowSettings settings) async {
    stored = settings;
  }
}

void main() {
  tearDown(() {
    ClinicWorkflowSettingsRepositoryProvider.testOverride = null;
  });

  group('PersistedClinicScheduleConfigSource', () {
    test('returns config when repo has settings', () async {
      final repo = _FakeWorkflowRepo(
        stored: ClinicWorkflowSettings(
          slotDurationMinutes: 20,
          lunchBreak: ClinicWorkflowSettings.defaultClinic().lunchBreak,
          weekdays: ClinicWorkflowSettings.defaultClinic().weekdays,
        ),
      );
      ClinicWorkflowSettingsRepositoryProvider.testOverride = repo;

      final source = const PersistedClinicScheduleConfigSource();
      final config = await source.loadForCurrentTenant();
      expect(config.slotDurationMinutes, 20);
      expect(repo.loadCount, 1);
    });

    test('null repo settings falls back to defaultClinic', () async {
      ClinicWorkflowSettingsRepositoryProvider.testOverride =
          _FakeWorkflowRepo(stored: null);

      final source = const PersistedClinicScheduleConfigSource();
      final config = await source.loadForCurrentTenant();
      final defaultCfg = ClinicScheduleConfig.defaultClinic();
      expect(config.slotDurationMinutes, defaultCfg.slotDurationMinutes);
      expect(config.activeWeekdays, defaultCfg.activeWeekdays);
    });

    test('invalid stored settings still produce safe config via mapper', () async {
      ClinicWorkflowSettingsRepositoryProvider.testOverride = _FakeWorkflowRepo(
        stored: ClinicWorkflowSettingsMapper.fromJson({
          'schemaVersion': 2,
        }),
      );

      final config = await const PersistedClinicScheduleConfigSource()
          .loadForCurrentTenant();
      expect(config.slotDurationMinutes, 30);
    });

    test('loadForDay uses weekday intervals', () async {
      final weekdays = ClinicWorkflowSettings.defaultClinic().weekdays;
      final monday = weekdays.first.copyWith(
        enabled: true,
        start: const TimeOfDay(hour: 10, minute: 0),
        end: const TimeOfDay(hour: 14, minute: 0),
      );
      final list = List<ClinicWeekdaySettings>.from(weekdays);
      list[0] = monday;

      ClinicWorkflowSettingsRepositoryProvider.testOverride = _FakeWorkflowRepo(
        stored: ClinicWorkflowSettings(
          slotDurationMinutes: 30,
          lunchBreak: ClinicWorkflowSettings.defaultClinic().lunchBreak.copyWith(
                enabled: false,
              ),
          weekdays: list,
        ),
      );

      final day = DateTime(2026, 5, 25);
      final config =
          await const PersistedClinicScheduleConfigSource().loadForDay(day);
      expect(config.workIntervals.length, 1);
      expect(config.workIntervals.first.start.hour, 10);
    });
  });
}
