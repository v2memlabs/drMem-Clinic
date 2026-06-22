import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_datetime_helper.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_remote_mapper.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_status_mapping.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_type_mapping.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';

void main() {
  group('AppointmentStatusMapping', () {
    test('round trip planlandi', () {
      expect(
        AppointmentStatusMapping.fromDb(
          AppointmentStatusMapping.toDb(AppointmentStatus.planlandi),
        ),
        AppointmentStatus.planlandi,
      );
    });

    test('unknown status falls back to planlandi', () {
      expect(
        AppointmentStatusMapping.fromDb('legacy_value'),
        AppointmentStatus.planlandi,
      );
    });
  });

  group('AppointmentTypeMapping', () {
    test('round trip ilkMuayene', () {
      expect(
        AppointmentTypeMapping.fromDb(
          AppointmentTypeMapping.toDb(AppointmentType.ilkMuayene),
        ),
        AppointmentType.ilkMuayene,
      );
    });

    test('unknown type falls back to kontrol', () {
      expect(
        AppointmentTypeMapping.fromDb('unknown'),
        AppointmentType.kontrol,
      );
    });
  });

  group('AppointmentRemoteMapper.fromRow', () {
    test('maps core fields and embed patient name', () {
      final appt = AppointmentRemoteMapper.fromRow({
        'id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        'tenant_id': 'tenant-1',
        'patient_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'appointment_at': '2026-05-21T09:30:00Z',
        'status': 'planned',
        'appointment_type': 'first_visit',
        'notes': 'Operasyon notu',
        'patients': {'first_name': 'Ayşe', 'last_name': 'Yılmaz'},
      });

      expect(appt.id, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
      expect(appt.patientId, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
      expect(appt.patientName, 'Ayşe Yılmaz');
      expect(appt.status, AppointmentStatus.planlandi);
      expect(appt.type, AppointmentType.ilkMuayene);
      expect(appt.notes, 'Operasyon notu');
      expect(appt.reason, '');
      expect(appt.controlDate, isNull);
      expect(appt.durationMinutes, AppointmentRemoteMapper.defaultDurationMinutes);
    });

    test('missing embed uses Hasta fallback', () {
      final appt = AppointmentRemoteMapper.fromRow({
        'id': 'id-1',
        'tenant_id': 't1',
        'patient_id': 'p1',
        'appointment_at': '2026-01-01T12:00:00Z',
        'status': 'arrived',
        'appointment_type': 'follow_up',
      });

      expect(appt.patientName, 'Hasta');
    });
  });

  group('AppointmentRemoteMapper write rows', () {
    test('toInsertRow omits id and sets tenant_id', () {
      final row = AppointmentRemoteMapper.toInsertRow(
        Appointment(
          id: 'client-id',
          patientId: 'patient-uuid',
          patientName: 'Deneme',
          appointmentDateTime: DateTime(2026, 5, 21, 14, 30),
          durationMinutes: 45,
          type: AppointmentType.kontrol,
          status: AppointmentStatus.planlandi,
          reason: 'Neden burada',
          notes: '  ',
        ),
        tenantId: 'tenant-scope',
      );

      expect(row.containsKey('id'), isFalse);
      expect(row['tenant_id'], 'tenant-scope');
      expect(row['patient_id'], 'patient-uuid');
      expect(row['status'], 'planned');
      expect(row['appointment_type'], 'follow_up');
      expect(row['notes'], isNull);
      expect(row['appointment_at'], isA<String>());
    });

    test('toCancelRow sets cancelled', () {
      expect(
        AppointmentRemoteMapper.toCancelRow()['status'],
        AppointmentStatusMapping.cancelled,
      );
    });

    test('toArchiveRow sets deleted_at only', () {
      final row = AppointmentRemoteMapper.toArchiveRow(
        at: DateTime.utc(2026, 5, 21, 10),
      );
      expect(row.containsKey('status'), isFalse);
      expect(row['deleted_at'], '2026-05-21T10:00:00.000Z');
    });
  });

  group('AppointmentDateTimeHelper', () {
    test('local to UTC ISO roundtrip preserves instant', () {
      final local = DateTime(2026, 5, 21, 15, 0);
      final utc = AppointmentDateTimeHelper.localDateTimeToUtc(local);
      final iso = AppointmentDateTimeHelper.toUtcIsoString(local);
      final parsed = AppointmentDateTimeHelper.parseFromDb(iso);
      expect(parsed, utc);
    });

    test('istanbul day bounds are 24h apart', () {
      final day = DateTime(2026, 5, 21);
      final start = AppointmentDateTimeHelper.istanbulDayStartUtc(day);
      final end = AppointmentDateTimeHelper.istanbulDayEndExclusiveUtc(day);
      expect(end.difference(start), const Duration(hours: 24));
    });

    test('istanbul today range is 24h', () {
      final range = AppointmentDateTimeHelper.istanbulTodayRangeUtc();
      expect(
        range.endExclusiveUtc.difference(range.startUtc),
        const Duration(hours: 24),
      );
    });

    test('local week range is 7 days', () {
      final range = AppointmentDateTimeHelper.localWeekRangeUtc(
        reference: DateTime(2026, 5, 21),
      );
      expect(
        range.endExclusiveUtc.difference(range.startUtc),
        const Duration(days: 7),
      );
    });
  });
}
