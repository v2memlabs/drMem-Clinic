import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/repository_registry.dart';
import 'package:v2mem_clinic/features/patient_files/data/mock_patient_file_metadata_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_provider.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_stub.dart';
import 'package:v2mem_clinic/features/patient_files/data/supabase_patient_file_metadata_repository.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    PatientFileMetadataRepositoryProvider.resetCache();
    AuthSession.clear();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  group('PatientFileMetadataRepositoryProvider', () {
    test('mock backend uses mock metadata repository not remote', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PatientFileMetadataRepositoryProvider.resetCache();

      expect(
        PatientFileMetadataRepositoryProvider.repository,
        isA<MockPatientFileMetadataRepository>(),
      );
      expect(
        PatientFileMetadataRepositoryProvider.usesRemotePatientFileMetadata,
        isFalse,
      );
    });

    test('supabase backend without init uses stub', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      PatientFileMetadataRepositoryProvider.resetCache();

      expect(
        PatientFileMetadataRepositoryProvider.repository,
        isA<PatientFileMetadataRepositoryStub>(),
      );
      expect(
        PatientFileMetadataRepositoryProvider.usesRemotePatientFileMetadata,
        isFalse,
      );
    });

    test('repository is metadata contract only — not Supabase remote type when stub', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PatientFileMetadataRepositoryProvider.resetCache();

      final repo = PatientFileMetadataRepositoryProvider.repository;
      expect(repo, isA<PatientFileMetadataRepository>());
      expect(repo, isNot(isA<SupabasePatientFileMetadataRepository>()));
    });

    test('resetCache allows re-resolve after backend change', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PatientFileMetadataRepositoryProvider.resetCache();
      expect(
        PatientFileMetadataRepositoryProvider.usesRemotePatientFileMetadata,
        isFalse,
      );

      AppBackendConfig.activeBackend = DataBackend.supabase;
      PatientFileMetadataRepositoryProvider.resetCache();
      expect(
        PatientFileMetadataRepositoryProvider.repository,
        isA<PatientFileMetadataRepositoryStub>(),
      );
      expect(
        PatientFileMetadataRepositoryProvider.usesRemotePatientFileMetadata,
        isFalse,
      );
    });

    test('nurse role does not enable remote flag without infra', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AuthSession.setUser(
        AppUser(
          id: 'n1',
          username: 'nurse',
          displayName: 'Nurse',
          role: AppRoles.nurse,
        ),
      );
      PatientFileMetadataRepositoryProvider.resetCache();

      expect(
        PatientFileMetadataRepositoryProvider.usesRemotePatientFileMetadata,
        isFalse,
      );
      expect(
        PatientFileMetadataRepositoryProvider.repository,
        isA<PatientFileMetadataRepositoryStub>(),
      );
    });

    test('doctor role alone does not enable remote without supabase init', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AuthSession.setUser(
        AppUser(
          id: 'd1',
          username: 'doc',
          displayName: 'Doc',
          role: AppRoles.doctor,
        ),
      );
      PatientFileMetadataRepositoryProvider.resetCache();

      expect(
        PatientFileMetadataRepositoryProvider.usesRemotePatientFileMetadata,
        isFalse,
      );
    });

    test('physiotherapist eligible for role gate but stub without infra', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AuthSession.setUser(
        AppUser(
          id: 'f1',
          username: 'ftr',
          displayName: 'FTR',
          role: AppRoles.physiotherapist,
        ),
      );
      PatientFileMetadataRepositoryProvider.resetCache();

      expect(
        PatientFileMetadataRepositoryProvider.repository,
        isA<PatientFileMetadataRepositoryStub>(),
      );
      expect(
        PatientFileMetadataRepositoryProvider.usesRemotePatientFileMetadata,
        isFalse,
      );
    });
  });

  group('RepositoryRegistry patientFileMetadata', () {
    test('exposes metadata repository via registry', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PatientFileMetadataRepositoryProvider.resetCache();

      expect(
        RepositoryRegistry.patientFileMetadata,
        isA<PatientFileMetadataRepository>(),
      );
      expect(RepositoryRegistry.usesRemotePatientFileMetadata, isFalse);
    });
  });
}
