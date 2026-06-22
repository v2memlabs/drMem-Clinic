import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository_error_mapper.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository_failure.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  group('AppointmentRepositoryErrorMapper', () {
    test('maps 23503 to patientNotFound', () {
      final ex = AppointmentRepositoryErrorMapper.toException(
        PostgrestException(message: 'fk', code: '23503'),
      );
      expect(ex.reason, AppointmentRepositoryFailure.patientNotFound);
    });

    test('maps 42501 to forbidden', () {
      final ex = AppointmentRepositoryErrorMapper.toException(
        PostgrestException(message: 'permission denied', code: '42501'),
      );
      expect(ex.reason, AppointmentRepositoryFailure.forbidden);
    });

    test('maps PGRST116 to notFound', () {
      final ex = AppointmentRepositoryErrorMapper.toException(
        PostgrestException(message: 'not found', code: 'PGRST116'),
      );
      expect(ex.reason, AppointmentRepositoryFailure.notFound);
    });
  });
}
