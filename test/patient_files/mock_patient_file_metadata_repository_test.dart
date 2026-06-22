import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/patient_files/data/mock_patient_file_metadata_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/mock_patient_file_metadata_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_list_data_source.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_provider.dart';

void main() {
  tearDown(() {
    PatientFileMetadataRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  group('MockPatientFileMetadataRepository', () {
    test('listPatientFiles returns files for patient without throwing', () async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PatientFileMetadataRepositoryProvider.resetCache();

      final repo = PatientFileMetadataRepositoryProvider.repository;
      expect(repo, isA<MockPatientFileMetadataRepository>());

      final files = await repo.listPatientFiles(patientId: 'p1');
      expect(files, isNotEmpty);
      expect(files.every((f) => f.patientId == 'p1'), isTrue);
    });

    test('empty patient returns empty list not notConfigured', () async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PatientFileMetadataRepositoryProvider.resetCache();

      final result = await PatientFileMetadataListDataSource.load(
        patientId: 'p-empty-unknown',
      );

      expect(result.hasError, isFalse);
      expect(result.isNotConfigured, isFalse);
      expect(result.files, isEmpty);
    });

    test('getById resolves mock file without throwing', () async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PatientFileMetadataRepositoryProvider.resetCache();

      final meta = await PatientFileMetadataRepositoryProvider.repository
          .getPatientFileMetadata('f1');
      expect(meta, isNotNull);
      expect(meta!.displayName, 'id_card.jpg');
      expect(meta.storagePath, isNotEmpty);
    });
  });
}
