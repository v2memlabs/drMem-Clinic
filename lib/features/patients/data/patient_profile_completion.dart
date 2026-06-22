import '../models/patient.dart';
import 'patient_remote_display.dart';
import 'patient_remote_mapper.dart';

/// Eksik hasta profil alanı — banner listesinde kullanılır.
enum PatientProfileMissingField {
  birthDate,
  gender,
  phone,
  identity,
}

/// Hasta profil tamamlama durumu (DB flag yok; alanlardan türetilir).
class PatientProfileCompletionStatus {
  final List<PatientProfileMissingField> missingFields;

  const PatientProfileCompletionStatus(this.missingFields);

  bool get isComplete => missingFields.isEmpty;

  List<PatientProfileMissingField> get displayFields =>
      missingFields.take(3).toList(growable: false);

  bool get hasMore => missingFields.length > 3;

  List<String> get missingLabels => displayFields.map(_labelFor).toList();

  static String _labelFor(PatientProfileMissingField field) {
    switch (field) {
      case PatientProfileMissingField.birthDate:
        return 'Doğum tarihi';
      case PatientProfileMissingField.gender:
        return 'Cinsiyet';
      case PatientProfileMissingField.phone:
        return 'Telefon';
      case PatientProfileMissingField.identity:
        return 'Kimlik bilgisi';
    }
  }
}

/// Hasta profil eksikliği — pure helper.
abstract final class PatientProfileCompletion {
  static PatientProfileCompletionStatus evaluate(Patient patient) {
    final missing = <PatientProfileMissingField>[];

    if (_isBirthDateMissing(patient)) {
      missing.add(PatientProfileMissingField.birthDate);
    }
    if (!PatientRemoteDisplay.showGender(patient)) {
      missing.add(PatientProfileMissingField.gender);
    }
    if (_isPhoneMissing(patient)) {
      missing.add(PatientProfileMissingField.phone);
    }
    if (!PatientRemoteDisplay.showIdentityNumber(patient)) {
      missing.add(PatientProfileMissingField.identity);
    }

    return PatientProfileCompletionStatus(missing);
  }

  static bool _isBirthDateMissing(Patient patient) {
    return patient.birthDate == PatientRemoteMapper.fallbackBirthDate;
  }

  static bool _isPhoneMissing(Patient patient) {
    if (!PatientRemoteDisplay.showPhone(patient)) return true;
    return !_isValidPhone(patient.phone);
  }

  static String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 12 && digits.startsWith('90')) {
      return digits.substring(digits.length - 10);
    }
    if (digits.length > 10 && digits.startsWith('0')) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  static bool _isValidPhone(String phone) => _normalizePhone(phone).length >= 10;
}
