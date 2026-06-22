import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_form_required_field_validator.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';
import 'package:v2mem_clinic/features/settings/models/patient_registration_settings.dart';
import 'package:v2mem_clinic/features/settings/models/patient_required_field.dart';

void main() {
  const settings = PatientRegistrationSettings(
    requiredFields: {
      PatientRequiredField.phone,
      PatientRequiredField.gender,
      PatientRequiredField.identityNumber,
    },
  );

  test('passes when required fields are filled', () {
    final error = PatientFormRequiredFieldValidator.validateDraft(
      settings: settings,
      phone: '05551234567',
      gender: 'Erkek',
      identityNumber: '12345678901',
      email: '',
      address: '',
    );
    expect(error, isNull);
  });

  test('fails when phone missing', () {
    final error = PatientFormRequiredFieldValidator.validateDraft(
      settings: settings,
      phone: '-',
      gender: 'Erkek',
      identityNumber: '123',
      email: '',
      address: '',
    );
    expect(error, contains('Telefon'));
  });

  test('fails when gender unspecified', () {
    final error = PatientFormRequiredFieldValidator.validateDraft(
      settings: settings,
      phone: '05551234567',
      gender: Patient.unspecifiedLabel,
      identityNumber: '123',
      email: '',
      address: '',
    );
    expect(error, contains('Cinsiyet'));
  });

  test('ignores optional fields when not configured', () {
    const emptySettings = PatientRegistrationSettings();
    final error = PatientFormRequiredFieldValidator.validateDraft(
      settings: emptySettings,
      phone: '',
      gender: Patient.unspecifiedLabel,
      identityNumber: '',
      email: '',
      address: '',
    );
    expect(error, isNull);
  });
}
