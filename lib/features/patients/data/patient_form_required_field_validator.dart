import '../../settings/models/patient_registration_settings.dart';
import '../../settings/models/patient_required_field.dart';
import '../models/patient.dart';
import 'quick_patient_create_data_source.dart';

/// Hasta formu — tenant zorunlu alan kuralları.
abstract final class PatientFormRequiredFieldValidator {
  static String? validateDraft({
    required PatientRegistrationSettings settings,
    required String phone,
    required String gender,
    required String identityNumber,
    required String email,
    required String address,
  }) {
    for (final field in settings.requiredFields) {
      final message = _validateField(
        field: field,
        phone: phone,
        gender: gender,
        identityNumber: identityNumber,
        email: email,
        address: address,
      );
      if (message != null) return message;
    }
    return null;
  }

  static String? validatePatient({
    required PatientRegistrationSettings settings,
    required Patient patient,
  }) {
    return validateDraft(
      settings: settings,
      phone: patient.phone,
      gender: patient.gender,
      identityNumber: patient.identityNumber,
      email: patient.email,
      address: patient.address,
    );
  }

  static String? _validateField({
    required PatientRequiredField field,
    required String phone,
    required String gender,
    required String identityNumber,
    required String email,
    required String address,
  }) {
    switch (field) {
      case PatientRequiredField.phone:
        final trimmed = phone.trim();
        if (trimmed.isEmpty || trimmed == '-') {
          return '${field.label} zorunludur.';
        }
        if (!QuickPatientCreateDataSource.isValidPhone(trimmed)) {
          return 'Geçerli bir telefon numarası girin.';
        }
        return null;
      case PatientRequiredField.gender:
        if (gender.trim().isEmpty || gender == Patient.unspecifiedLabel) {
          return '${field.label} zorunludur.';
        }
        return null;
      case PatientRequiredField.identityNumber:
        if (identityNumber.trim().isEmpty) {
          return '${field.label} zorunludur.';
        }
        return null;
      case PatientRequiredField.email:
        final trimmed = email.trim();
        if (trimmed.isEmpty || !trimmed.contains('@')) {
          return '${field.label} zorunludur.';
        }
        return null;
      case PatientRequiredField.address:
        if (address.trim().isEmpty) {
          return '${field.label} zorunludur.';
        }
        return null;
    }
  }
}
