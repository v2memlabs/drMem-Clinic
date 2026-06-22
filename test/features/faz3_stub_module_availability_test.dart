import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_summary_module_availability.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_module_availability.dart';
import 'package:v2mem_clinic/features/patient_tags/data/patient_tag_module_availability.dart';
import 'package:v2mem_clinic/features/settings/data/settings_image_storage_availability.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_module_availability.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('patient tags operational in mock backend', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    expect(PatientTagModuleAvailability.isOperational, isTrue);
  });

  test('patient tags unavailable in supabase without session', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AuthSession.clear();
    expect(PatientTagModuleAvailability.isOperational, isFalse);
  });

  test('settings image storage operational in mock backend', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    expect(SettingsImageStorageAvailability.isOperational, isTrue);
  });

  test('settings image storage unavailable in supabase without session', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'doc',
        displayName: 'Dr',
        role: 'doctor',
      ),
    );
    expect(SettingsImageStorageAvailability.isOperational, isFalse);
  });

  test('timeline operational in mock backend', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    expect(TimelineModuleAvailability.isOperational, isTrue);
  });

  test('timeline unavailable in supabase without session', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AuthSession.clear();
    expect(TimelineModuleAvailability.isOperational, isFalse);
  });

  test('patient file metadata operational in mock backend', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    expect(PatientFileMetadataModuleAvailability.isOperational, isTrue);
  });

  test('patient file metadata unavailable in supabase without session', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AuthSession.clear();
    expect(PatientFileMetadataModuleAvailability.isOperational, isFalse);
  });

  test('clinical summaries operational in mock backend', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    expect(ClinicalSummaryModuleAvailability.assistantOperational, isTrue);
    expect(
      ClinicalSummaryModuleAvailability.physiotherapistOperational,
      isTrue,
    );
  });

  test('clinical summaries unavailable in supabase without session', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AuthSession.clear();
    expect(ClinicalSummaryModuleAvailability.assistantOperational, isFalse);
    expect(
      ClinicalSummaryModuleAvailability.physiotherapistOperational,
      isFalse,
    );
  });
}
