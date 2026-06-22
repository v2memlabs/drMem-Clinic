import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../models/patient.dart';

/// KVKK — kimlik/telefon maskeleme (UI only).
abstract final class PatientIdentityPrivacy {
  /// 11 haneli T.C. → `12*******01`; geçersiz/boş → null.
  static String? maskTurkishNationalId(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 || !RegExp(r'^\d{11}$').hasMatch(digits)) {
      return null;
    }
    return '${digits.substring(0, 2)}*******${digits.substring(9, 11)}';
  }

  /// Mobil örnek: `05321234567` → `05xx xxx 45 67`.
  static String? formatMaskedPhone(String? raw) {
    if (raw == null) return null;
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 && digits.startsWith('5')) {
      digits = '0$digits';
    }
    if (digits.length != 11 || !digits.startsWith('05')) {
      return null;
    }
    return '${digits.substring(0, 2)}xx xxx '
        '${digits.substring(7, 9)} ${digits.substring(9, 11)}';
  }

  static bool isTurkishNationalIdType(Patient patient) {
    return patient.identityType.trim() == Patient.defaultIdentityType;
  }

  /// Muayene detay bandında maskeli T.C. — doktor/asistan; FTR/hemşire hayır.
  static bool shouldShowMaskedNationalIdInEncounterBand() {
    final role = AuthSession.currentUser?.role;
    if (role == null) return false;
    return role == AppRoles.doctor || role == AppRoles.assistant;
  }

  /// Hasta detay, liste, seçici — maskeli T.C. görünürlüğü.
  static bool shouldShowMaskedNationalId() {
    final role = AuthSession.currentUser?.role;
    if (role == null) return false;
    return role == AppRoles.doctor ||
        role == AppRoles.assistant ||
        role == AppRoles.nurse;
  }

  /// UI'da gösterilecek kimlik numarası — ham 11 haneli T.C. asla dönmez.
  static String? displayIdentityNumber(Patient patient) {
    final raw = patient.identityNumber.trim();
    if (raw.isEmpty) return null;

    if (isTurkishNationalIdType(patient)) {
      if (!shouldShowMaskedNationalId()) return null;
      return maskTurkishNationalId(raw);
    }

    return patient.displayValue(raw);
  }

  /// Liste/seçici/detay satırı: `T.C. Kimlik No: 12*******01`
  static String? formatIdentityLineForDisplay(Patient patient) {
    final display = displayIdentityNumber(patient);
    if (display == null) return null;
    return '${patient.identityType}: $display';
  }

  /// Maskeli T.C. satırı: `T.C. Kimlik No: 12*******01`
  static String? maskedNationalIdLine(Patient patient) {
    if (!shouldShowMaskedNationalIdInEncounterBand()) return null;
    if (!isTurkishNationalIdType(patient)) return null;
    final masked = maskTurkishNationalId(patient.identityNumber);
    if (masked == null) return null;
    return '${patient.identityNumberFieldLabel}: $masked';
  }
}
