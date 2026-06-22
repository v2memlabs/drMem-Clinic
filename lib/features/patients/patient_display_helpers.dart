import 'data/patient_identity_privacy.dart';
import 'data/patient_remote_display.dart';
import 'models/patient.dart';

/// Hasta liste görünümü — ad formatı, Türkçe sıralama ve harf indeksi.
abstract final class PatientDisplayHelpers {
  static const String unnamedPatient = 'İsimsiz Hasta';

  /// Türkçe alfabe — indeks ve sıralama.
  static const List<String> turkishIndexLetters = [
    'A',
    'B',
    'C',
    'Ç',
    'D',
    'E',
    'F',
    'G',
    'Ğ',
    'H',
    'I',
    'İ',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'Ö',
    'P',
    'R',
    'S',
    'Ş',
    'T',
    'U',
    'Ü',
    'V',
    'Y',
    'Z',
  ];

  /// Liste başlığı: SOYAD, Ad
  static String formatListName(Patient patient) {
    final last = patient.lastName.trim();
    final first = patient.firstName.trim();
    if (last.isEmpty && first.isEmpty) return unnamedPatient;
    if (last.isEmpty) return first;
    if (first.isEmpty) return turkishUpperString(last);
    return '${turkishUpperString(last)}, $first';
  }

  /// Soyad → indeks harfi (I / İ ayrımı).
  static String indexLetterForPatient(Patient patient) {
    final last = patient.lastName.trim();
    if (last.isEmpty) {
      final first = patient.firstName.trim();
      if (first.isEmpty) return '#';
      return turkishIndexLetterFromChar(first.runes.first);
    }
    return turkishIndexLetterFromChar(last.runes.first);
  }

  static String turkishIndexLetterFromChar(int rune) {
    final ch = String.fromCharCode(rune);
    final upper = turkishUpperChar(ch);
    if (upper == 'I' || upper == 'İ') return upper;
    for (final letter in turkishIndexLetters) {
      if (letter == upper) return letter;
    }
    return '#';
  }

  static bool matchesLetterFilter(Patient patient, String? letter) {
    if (letter == null || letter.isEmpty) return true;
    return indexLetterForPatient(patient) == letter;
  }

  static List<Patient> sortByLastName(List<Patient> patients) {
    final copy = List<Patient>.from(patients);
    copy.sort((a, b) {
      final byLast = compareTurkish(a.lastName, b.lastName);
      if (byLast != 0) return byLast;
      final byFirst = compareTurkish(a.firstName, b.firstName);
      if (byFirst != 0) return byFirst;
      return a.fileNumber.compareTo(b.fileNumber);
    });
    return copy;
  }

  static Set<String> enabledIndexLetters(Iterable<Patient> patients) {
    final letters = <String>{};
    for (final p in patients) {
      final letter = indexLetterForPatient(p);
      if (letter != '#') letters.add(letter);
    }
    return letters;
  }

  static int compareTurkish(String a, String b) {
    final ra = a.trim().runes.toList();
    final rb = b.trim().runes.toList();
    final maxLen = ra.length > rb.length ? ra.length : rb.length;
    for (var i = 0; i < maxLen; i++) {
      final oa = i < ra.length ? _turkishOrderForRune(ra[i]) : -1;
      final ob = i < rb.length ? _turkishOrderForRune(rb[i]) : -1;
      if (oa != ob) return oa.compareTo(ob);
    }
    return ra.length.compareTo(rb.length);
  }

  static String turkishUpperString(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      buffer.write(turkishUpperChar(String.fromCharCode(rune)));
    }
    return buffer.toString();
  }

  static int _turkishOrderForRune(int rune) {
    final ch = turkishUpperChar(String.fromCharCode(rune));
    final idx = turkishIndexLetters.indexOf(ch);
    return idx >= 0 ? idx : 999;
  }

  static String turkishUpperChar(String char) {
    switch (char) {
      case 'i':
        return 'İ';
      case 'ı':
        return 'I';
      case 'ş':
        return 'Ş';
      case 'ğ':
        return 'Ğ';
      case 'ü':
        return 'Ü';
      case 'ö':
        return 'Ö';
      case 'ç':
        return 'Ç';
      default:
        return char.toUpperCase();
    }
  }

  static String formatAgeLine(Patient patient) => '${patient.age} yaş';

  /// Liste satırı: yaş + kısa cinsiyet (ör. `42 yaş · E`).
  static String formatAgeGenderLine(Patient patient) {
    final age = formatAgeLine(patient);
    final g = patient.genderShortLabel;
    if (g.isEmpty) return age;
    return '$age · $g';
  }

  /// Liste satırı demografi — yaş/cinsiyet + dosya no.
  static String? formatListDemographicLine(Patient patient) {
    final ageGender = formatAgeGenderLine(patient);
    final file = patient.fileNumber.trim();
    if (file.isEmpty) return ageGender;
    return '$ageGender · Dosya: $file';
  }

  static String formatLastVisit(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d.$m.${local.year}';
  }

  static String formatPhone(Patient patient) {
    final phone = patient.phone.trim();
    if (phone.isEmpty || phone == Patient.unspecifiedLabel) return '—';
    return phone;
  }

  /// Tam cinsiyet etiketi (Erkek / Kadın).
  static String? formatGenderLabel(Patient patient) {
    if (!PatientRemoteDisplay.showGender(patient)) return null;
    return patient.gender.trim();
  }

  /// Muayene detay kimlik bandı — `48 yaş · Erkek · 05xx xxx 45 67`.
  static String? formatEncounterIdentityDemographyLine(Patient patient) {
    final parts = <String>[];
    parts.add('${patient.age} yaş');
    final gender = formatGenderLabel(patient);
    if (gender != null) parts.add(gender);
    final phone = PatientIdentityPrivacy.formatMaskedPhone(patient.phone);
    if (phone != null) parts.add(phone);
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static List<String> visibleTagChips(Patient patient, {int max = 2}) {
    if (patient.tags.isEmpty) return const [];
    return patient.tags.take(max).toList();
  }
}
