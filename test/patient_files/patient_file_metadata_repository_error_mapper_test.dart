import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_error_mapper.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_failure.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  test('maps PostgREST 42501 to forbidden', () {
    final ex = PatientFileMetadataRepositoryErrorMapper.toException(
      const PostgrestException(
        message: 'row-level security violation',
        code: '42501',
      ),
    );
    expect(ex.reason, PatientFileMetadataRepositoryFailure.forbidden);
  });

  test('maps PGRST116 to notFound', () {
    final ex = PatientFileMetadataRepositoryErrorMapper.toException(
      const PostgrestException(
        message: 'not found',
        code: 'PGRST116',
      ),
    );
    expect(ex.reason, PatientFileMetadataRepositoryFailure.notFound);
  });
}
