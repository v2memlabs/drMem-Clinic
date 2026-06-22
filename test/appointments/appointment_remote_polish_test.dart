import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_list_refresh.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_list_state_messages.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_remote_display.dart';

void main() {
  group('AppointmentListRefresh', () {
    test('isStale after markStale', () {
      final seen = AppointmentListRefresh.version;
      expect(AppointmentListRefresh.isStale(seen), isFalse);
      AppointmentListRefresh.markStale();
      expect(AppointmentListRefresh.isStale(seen), isTrue);
    });
  });

  group('AppointmentListStateMessages', () {
    test('empty db title when no filters and empty source', () {
      expect(
        AppointmentListStateMessages.emptyTitle(
          search: '',
          hasStatusFilter: false,
          hasPatientFilter: false,
          emptySourceList: true,
        ),
        AppointmentListStateMessages.emptyDayTitle,
      );
    });

    test('search empty title', () {
      expect(
        AppointmentListStateMessages.emptyTitle(
          search: 'test',
          hasStatusFilter: false,
          hasPatientFilter: false,
          emptySourceList: true,
        ),
        AppointmentListStateMessages.emptySearchTitle,
      );
    });
  });

  group('AppointmentRemoteDisplay', () {
    test('patientDisplayName fallback', () {
      expect(
        AppointmentRemoteDisplay.patientDisplayName('Hasta'),
        'Hasta bilgisi',
      );
      expect(
        AppointmentRemoteDisplay.patientDisplayName('Ayşe Yılmaz'),
        'Ayşe Yılmaz',
      );
    });
  });
}
