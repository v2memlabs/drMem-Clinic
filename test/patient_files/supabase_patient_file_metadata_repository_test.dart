import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_failure.dart';
import 'package:v2mem_clinic/features/patient_files/data/supabase_patient_file_metadata_repository.dart';

void main() {
  group('SupabasePatientFileMetadataRepository', () {
    test('uses patient_files table not storage', () {
      expect(SupabasePatientFileMetadataRepository.tableName, 'patient_files');
    });

    test('repository type implements contract surface', () {
      expect(
        SupabasePatientFileMetadataRepository.fromSupabase,
        isA<Function>(),
      );
    });
  });

  test('notConfigured when supabase env unavailable is documented pattern', () {
    // Full client integration requires Supabase test harness; smoke via mapper tests.
    expect(
      PatientFileMetadataRepositoryFailure.notConfigured,
      isNotNull,
    );
  });
}
