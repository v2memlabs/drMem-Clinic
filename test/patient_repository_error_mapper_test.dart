import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository_error_mapper.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository_failure.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  group('PatientRepositoryErrorMapper', () {
    test('maps 23505 to duplicateFileNumber', () {
      final ex = PatientRepositoryErrorMapper.toException(
        PostgrestException(
          message: 'duplicate',
          code: '23505',
        ),
      );
      expect(ex.reason, PatientRepositoryFailure.duplicateFileNumber);
    });

    test('maps 42501 to forbidden', () {
      final ex = PatientRepositoryErrorMapper.toException(
        PostgrestException(
          message: 'permission denied',
          code: '42501',
        ),
      );
      expect(ex.reason, PatientRepositoryFailure.forbidden);
    });

    test('maps PGRST116 to notFound', () {
      final ex = PatientRepositoryErrorMapper.toException(
        PostgrestException(
          message: 'not found',
          code: 'PGRST116',
        ),
      );
      expect(ex.reason, PatientRepositoryFailure.notFound);
    });
  });
}
