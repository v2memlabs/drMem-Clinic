import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_error_mapper.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_failure.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  group('ClinicalEncounterRepositoryErrorMapper', () {
    test('maps 23503 patient_id to patientNotFound', () {
      final ex = ClinicalEncounterRepositoryErrorMapper.toException(
        PostgrestException(
          message: 'violates foreign key constraint on patient_id',
          code: '23503',
        ),
      );
      expect(ex.reason, ClinicalEncounterRepositoryFailure.patientNotFound);
    });

    test('maps 23503 appointment_id to appointmentNotFound', () {
      final ex = ClinicalEncounterRepositoryErrorMapper.toException(
        PostgrestException(
          message: 'violates foreign key constraint',
          details: 'Key (appointment_id)=... is not present in table "appointments"',
          code: '23503',
        ),
      );
      expect(ex.reason, ClinicalEncounterRepositoryFailure.appointmentNotFound);
    });

    test('maps 42501 to forbidden', () {
      final ex = ClinicalEncounterRepositoryErrorMapper.toException(
        PostgrestException(message: 'permission denied', code: '42501'),
      );
      expect(ex.reason, ClinicalEncounterRepositoryFailure.forbidden);
    });

    test('maps PGRST116 to notFound', () {
      final ex = ClinicalEncounterRepositoryErrorMapper.toException(
        PostgrestException(message: 'not found', code: 'PGRST116'),
      );
      expect(ex.reason, ClinicalEncounterRepositoryFailure.notFound);
    });

    test('passes through ClinicalEncounterRepositoryException', () {
      const original = ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.noActiveTenant,
      );
      final ex = ClinicalEncounterRepositoryErrorMapper.toException(original);
      expect(identical(ex, original), isTrue);
    });
  });
}
