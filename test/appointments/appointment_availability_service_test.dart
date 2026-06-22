import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_availability_service.dart';
import 'package:v2mem_clinic/features/appointments/data/staff_leave_availability_helper.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment_slot.dart';
import 'package:v2mem_clinic/features/appointments/models/clinic_schedule_config.dart';
import 'package:v2mem_clinic/features/settings/data/clinic_workflow_settings_mapper.dart';
import 'package:v2mem_clinic/features/settings/models/clinic_workflow_settings.dart';
import 'package:v2mem_clinic/features/settings/models/staff_leave_record.dart';

Appointment _appointment({
  required String id,
  required DateTime at,
  AppointmentStatus status = AppointmentStatus.planlandi,
  int durationMinutes = 30,
}) {
  return Appointment(
    id: id,
    patientId: 'p1',
    patientName: 'Test',
    appointmentDateTime: at,
    durationMinutes: durationMinutes,
    type: AppointmentType.kontrol,
    status: status,
    reason: '',
  );
}

DateTime _mondayAt(int hour, int minute) {
  // 2026-05-25 is Monday
  return DateTime(2026, 5, 25, hour, minute);
}

void main() {
  final config = ClinicScheduleConfig.defaultClinic();

  group('AppointmentAvailabilityService', () {
    test('weekend returns workingDayClosed', () {
      final sunday = DateTime(2026, 5, 24);
      final result = AppointmentAvailabilityService.buildSlots(
        day: sunday,
        config: config,
        existingAppointments: const [],
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      expect(result.reason, AppointmentDayAvailabilityReason.workingDayClosed);
      expect(result.slots, isEmpty);
    });

    test('empty work intervals returns workingDayClosed', () {
      final monday = DateTime(2026, 5, 26);
      final cfg = ClinicScheduleConfig(
        activeWeekdays: const {1, 2, 3, 4, 5},
        workIntervals: const [],
        slotDurationMinutes: 30,
      );
      final result = AppointmentAvailabilityService.buildSlots(
        day: monday,
        config: cfg,
        existingAppointments: const [],
        now: DateTime(2026, 5, 26, 8),
        allowPastSlots: true,
      );
      expect(result.reason, AppointmentDayAvailabilityReason.workingDayClosed);
      expect(result.slots, isEmpty);
    });

    test('closed date returns closedDate', () {
      final closed = DateTime(2026, 12, 31);
      final cfg = ClinicScheduleConfig(
        activeWeekdays: config.activeWeekdays,
        workIntervals: config.workIntervals,
        slotDurationMinutes: config.slotDurationMinutes,
        closedDates: {closed},
      );
      final result = AppointmentAvailabilityService.buildSlots(
        day: closed,
        config: cfg,
        existingAppointments: const [],
        now: DateTime(2026, 12, 30),
        allowPastSlots: true,
      );
      expect(result.reason, AppointmentDayAvailabilityReason.closedDate);
    });

    test('generates slots without lunch break', () {
      final result = AppointmentAvailabilityService.buildSlots(
        day: _mondayAt(0, 0),
        config: config,
        existingAppointments: const [],
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      final labels = result.slots.map((s) => s.label).toList();
      expect(labels, contains('09:00'));
      expect(labels, contains('12:00'));
      expect(labels, isNot(contains('12:30')));
      expect(labels, contains('13:30'));
      expect(labels, contains('16:30'));
    });

    test('planned appointment blocks overlapping slot', () {
      final busy = _appointment(
        id: 'a1',
        at: _mondayAt(9, 0),
        status: AppointmentStatus.planlandi,
      );
      final result = AppointmentAvailabilityService.buildSlots(
        day: _mondayAt(0, 0),
        config: config,
        existingAppointments: [busy],
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      final nine = result.slots.firstWhere((s) => s.label == '09:00');
      expect(nine.isAvailable, isFalse);
    });

    test('cancelled appointment does not block slot', () {
      final cancelled = _appointment(
        id: 'a1',
        at: _mondayAt(9, 0),
        status: AppointmentStatus.iptal,
      );
      final result = AppointmentAvailabilityService.buildSlots(
        day: _mondayAt(0, 0),
        config: config,
        existingAppointments: [cancelled],
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      final nine = result.slots.firstWhere((s) => s.label == '09:00');
      expect(nine.isAvailable, isTrue);
    });

    test('excludeAppointmentId skips own overlap', () {
      final self = _appointment(
        id: 'edit-me',
        at: _mondayAt(10, 0),
      );
      final result = AppointmentAvailabilityService.buildSlots(
        day: _mondayAt(0, 0),
        config: config,
        existingAppointments: [self],
        excludeAppointmentId: 'edit-me',
        selectedSlotStart: _mondayAt(10, 0),
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      final ten = result.slots.firstWhere((s) => s.label == '10:00');
      expect(ten.isAvailable, isTrue);
      expect(ten.isSelected, isTrue);
    });

    test('preserve current slot outside grid adds current appointment slot', () {
      final result = AppointmentAvailabilityService.buildSlots(
        day: _mondayAt(0, 0),
        config: config,
        existingAppointments: const [],
        preserveCurrentSlotStart: _mondayAt(8, 15),
        preserveCurrentDurationMinutes: 30,
        selectedSlotStart: _mondayAt(8, 15),
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      expect(
        result.slots.any((s) => s.isCurrentAppointmentSlot && s.label == '08:15'),
        isTrue,
      );
    });

    test('custom weekday hours via workflow mapper', () {
      final weekdays = ClinicWorkflowSettings.defaultClinic().weekdays;
      final tuesday = weekdays[1].copyWith(
        enabled: true,
        start: const TimeOfDay(hour: 10, minute: 0),
        end: const TimeOfDay(hour: 12, minute: 0),
      );
      final list = List<ClinicWeekdaySettings>.from(weekdays);
      list[1] = tuesday;
      final settings = ClinicWorkflowSettings(
        slotDurationMinutes: 30,
        lunchBreak: ClinicWorkflowSettings.defaultClinic().lunchBreak.copyWith(
              enabled: false,
            ),
        weekdays: list,
      );
      final tuesdayDay = DateTime(2026, 5, 26);
      final cfg = ClinicWorkflowSettingsMapper.toScheduleConfigForDay(
        settings,
        tuesdayDay,
      );
      final result = AppointmentAvailabilityService.buildSlots(
        day: tuesdayDay,
        config: cfg,
        existingAppointments: const [],
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      final labels = result.slots.map((s) => s.label).toList();
      expect(labels, contains('10:00'));
      expect(labels, contains('11:00'));
      expect(labels, isNot(contains('09:00')));
    });

    test('custom slot duration from workflow settings', () {
      final settings = ClinicWorkflowSettings(
        slotDurationMinutes: 15,
        lunchBreak: ClinicWorkflowSettings.defaultClinic().lunchBreak.copyWith(
              enabled: false,
            ),
        weekdays: ClinicWorkflowSettings.defaultClinic().weekdays,
      );
      final monday = DateTime(2026, 5, 25);
      final cfg = ClinicWorkflowSettingsMapper.toScheduleConfigForDay(
        settings,
        monday,
      );
      final result = AppointmentAvailabilityService.buildSlots(
        day: monday,
        config: cfg,
        existingAppointments: const [],
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      expect(result.slots.any((s) => s.label == '09:15'), isTrue);
    });

    test('lunch disabled workflow produces continuous slots', () {
      final settings = ClinicWorkflowSettings(
        slotDurationMinutes: 30,
        lunchBreak: ClinicWorkflowSettings.defaultClinic().lunchBreak.copyWith(
              enabled: false,
            ),
        weekdays: ClinicWorkflowSettings.defaultClinic().weekdays,
      );
      final monday = DateTime(2026, 5, 25);
      final cfg = ClinicWorkflowSettingsMapper.toScheduleConfigForDay(
        settings,
        monday,
      );
      final result = AppointmentAvailabilityService.buildSlots(
        day: monday,
        config: cfg,
        existingAppointments: const [],
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      expect(result.slots.map((s) => s.label), contains('12:30'));
    });

    test('active staff leave blocks overlapping slot', () {
      final leaveBlocks = StaffLeaveAvailabilityHelper.blocksForDay(
        calendarDay: _mondayAt(0, 0),
        leaves: [
          StaffLeaveRecord(
            id: 'l1',
            staffDisplayName: 'Dr. İzin',
            leaveType: StaffLeaveType.annual,
            startsAt: _mondayAt(10, 0),
            endsAt: _mondayAt(11, 0),
            status: StaffLeaveStatus.active,
            createdAt: DateTime(2026, 5, 20),
            updatedAt: DateTime(2026, 5, 20),
          ),
        ],
      );
      final result = AppointmentAvailabilityService.buildSlots(
        day: _mondayAt(0, 0),
        config: config,
        existingAppointments: const [],
        staffLeaveBlocks: leaveBlocks,
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      final ten = result.slots.firstWhere((s) => s.label == '10:00');
      expect(ten.isAvailable, isFalse);
      expect(ten.disabledReason, 'İzinli: Dr. İzin');
      final eleven = result.slots.firstWhere((s) => s.label == '11:00');
      expect(eleven.isAvailable, isTrue);
    });

    test('appointment overlap takes precedence over leave reason', () {
      final busy = _appointment(id: 'a1', at: _mondayAt(10, 0));
      final leaveBlocks = StaffLeaveAvailabilityHelper.blocksForDay(
        calendarDay: _mondayAt(0, 0),
        leaves: [
          StaffLeaveRecord(
            id: 'l1',
            staffDisplayName: 'Dr. İzin',
            leaveType: StaffLeaveType.annual,
            startsAt: _mondayAt(10, 0),
            endsAt: _mondayAt(11, 0),
            status: StaffLeaveStatus.active,
            createdAt: DateTime(2026, 5, 20),
            updatedAt: DateTime(2026, 5, 20),
          ),
        ],
      );
      final result = AppointmentAvailabilityService.buildSlots(
        day: _mondayAt(0, 0),
        config: config,
        existingAppointments: [busy],
        staffLeaveBlocks: leaveBlocks,
        now: DateTime(2026, 5, 20, 8),
        allowPastSlots: true,
      );
      final ten = result.slots.firstWhere((s) => s.label == '10:00');
      expect(ten.disabledReason, 'Dolu');
    });

    test('gelmedi and ertelendi block availability', () {
      for (final status in [
        AppointmentStatus.gelmedi,
        AppointmentStatus.ertelendi,
      ]) {
        final busy = _appointment(id: 'x', at: _mondayAt(11, 0), status: status);
        final result = AppointmentAvailabilityService.buildSlots(
          day: _mondayAt(0, 0),
          config: config,
          existingAppointments: [busy],
          now: DateTime(2026, 5, 20, 8),
          allowPastSlots: true,
        );
        final slot = result.slots.firstWhere((s) => s.label == '11:00');
        expect(slot.isAvailable, isFalse, reason: status.toString());
      }
    });
  });
}
