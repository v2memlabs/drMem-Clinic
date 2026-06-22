import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/settings/app_settings.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_settings_json_mapper.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_settings_repository.dart';
import 'package:v2mem_clinic/features/settings/models/patient_registration_settings.dart';
import 'package:v2mem_clinic/features/settings/models/patient_required_field.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_preferences.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_security_settings.dart';

void main() {
  test('mergePreferences preserves contact block', () {
    const existing = {
      'contact': {
        'phone': '0212',
        'email': 'klinik@test.local',
      },
      'date_time_format': 'iso',
    };
    const preferences = TenantPreferences(
      dateTimeFormat: DateTimeFormatKind.longTurkish,
      languageCode: 'en',
      themeMode: AppThemeModeKind.dark,
    );

    final merged = TenantSettingsJsonMapper.mergePreferences(existing, preferences);

    expect(merged['contact'], isA<Map>());
    expect((merged['contact'] as Map)['phone'], '0212');
    expect(merged['date_time_format'], 'longTurkish');
    expect(merged['language_code'], 'en');
    expect(merged['theme_mode'], 'dark');
  });

  test('mergeContact preserves preferences block', () {
    const existing = {
      'date_time_format': 'iso',
      'language_code': 'tr',
      'theme_mode': 'light',
    };
    const contact = TenantContactInfo(
      phone: '0555',
      website: 'https://klinik.test',
    );

    final merged = TenantSettingsJsonMapper.mergeContact(existing, contact);

    expect(merged['date_time_format'], 'iso');
    expect((merged['contact'] as Map)['phone'], '0555');
    expect((merged['contact'] as Map)['website'], 'https://klinik.test');
  });

  test('mergePatient preserves other settings_json blocks', () {
    const existing = {
      'contact': {'phone': '0212'},
      'branding': {'logo_path': 'tenants/x/branding/logo.png'},
    };
    const patient = PatientRegistrationSettings(
      fileNumberFormat: 'A-{seq}',
      seqPadding: 3,
    );

    final merged = TenantSettingsJsonMapper.mergePatient(existing, patient);

    expect((merged['contact'] as Map)['phone'], '0212');
    expect((merged['branding'] as Map)['logo_path'], 'tenants/x/branding/logo.png');
    expect((merged['patient'] as Map)['file_number_format'], 'A-{seq}');
    expect((merged['patient'] as Map)['file_number_seq_padding'], 3);
  });

  test('mergeSecurity preserves other settings_json blocks', () {
    const existing = {
      'contact': {'phone': '0212'},
      'patient': {'file_number_format': 'A-{seq}'},
    };
    const security = TenantSecuritySettings(
      autoLockDuration: AutoLockDurationKind.min30,
    );

    final merged = TenantSettingsJsonMapper.mergeSecurity(existing, security);

    expect((merged['contact'] as Map)['phone'], '0212');
    expect((merged['patient'] as Map)['file_number_format'], 'A-{seq}');
    expect((merged['security'] as Map)['auto_lock_duration'], 'min30');
  });

  test('securityFromJson reads auto_lock_duration', () {
    const json = {
      'security': {'auto_lock_duration': 'min5'},
    };
    final settings = TenantSettingsJsonMapper.securityFromJson(json);
    expect(settings.autoLockDuration, AutoLockDurationKind.min5);
  });

  test('patientFromJson reads required_fields', () {
    const json = {
      'patient': {
        'file_number_format': 'H-{year}-{seq}',
        'required_fields': ['phone', 'gender'],
      },
    };
    final settings = TenantSettingsJsonMapper.patientFromJson(json);
    expect(settings.requiredFields, {
      PatientRequiredField.phone,
      PatientRequiredField.gender,
    });
  });
}
