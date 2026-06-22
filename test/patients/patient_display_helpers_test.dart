import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';
import 'package:v2mem_clinic/features/patients/patient_display_helpers.dart';

Patient _patient({
  required String firstName,
  required String lastName,
  String fileNumber = 'A-001',
}) {
  return Patient(
    id: 'id-$lastName',
    fileNumber: fileNumber,
    firstName: firstName,
    lastName: lastName,
    phone: '05xx',
    birthDate: DateTime(1990, 1, 1),
    lastVisitDate: DateTime(2026, 5, 1),
    primaryComplaint: '',
    bodyRegion: '',
  );
}

void main() {
  group('PatientDisplayHelpers.formatListName', () {
    test('formats as SOYAD, Ad', () {
      final p = _patient(firstName: 'Mehmet', lastName: 'Yalçınozan');
      expect(PatientDisplayHelpers.formatListName(p), 'YALÇINOZAN, Mehmet');
    });

    test('formats Ayşe Demir', () {
      final p = _patient(firstName: 'Ayşe', lastName: 'Demir');
      expect(PatientDisplayHelpers.formatListName(p), 'DEMİR, Ayşe');
    });

    test('unnamed fallback', () {
      final p = _patient(firstName: '', lastName: '');
      expect(PatientDisplayHelpers.formatListName(p), PatientDisplayHelpers.unnamedPatient);
    });
  });

  group('PatientDisplayHelpers.sortByLastName', () {
    test('sorts Turkish alphabetically by surname', () {
      final list = [
        _patient(firstName: 'A', lastName: 'Yılmaz'),
        _patient(firstName: 'B', lastName: 'Demir'),
        _patient(firstName: 'C', lastName: 'Çelik'),
      ];
      final sorted = PatientDisplayHelpers.sortByLastName(list);
      expect(sorted.map((p) => p.lastName).toList(), ['Çelik', 'Demir', 'Yılmaz']);
    });
  });

  group('PatientDisplayHelpers.indexLetter', () {
    test('Öztürk surname starts with Ö', () {
      final p = _patient(firstName: 'İlker', lastName: 'Öztürk');
      expect(PatientDisplayHelpers.indexLetterForPatient(p), 'Ö');
    });

    test('letter filter matches surname initial', () {
      final p = _patient(firstName: 'Ali', lastName: 'Kaya');
      expect(PatientDisplayHelpers.matchesLetterFilter(p, 'K'), isTrue);
      expect(PatientDisplayHelpers.matchesLetterFilter(p, 'D'), isFalse);
    });
  });

  group('PatientDisplayHelpers.formatAgeGenderLine', () {
    test('shows age and gender short label', () {
      final p = _patient(firstName: 'Ali', lastName: 'Kaya').copyWith(
        gender: 'Erkek',
        birthDate: DateTime(1984, 6, 1),
      );
      expect(PatientDisplayHelpers.formatAgeGenderLine(p), contains('yaş'));
      expect(PatientDisplayHelpers.formatAgeGenderLine(p), contains('· E'));
    });

    test('shows only age when gender unspecified', () {
      final p = _patient(firstName: 'Ayşe', lastName: 'Demir');
      expect(
        PatientDisplayHelpers.formatAgeGenderLine(p),
        PatientDisplayHelpers.formatAgeLine(p),
      );
    });
  });

  group('PatientDisplayHelpers.turkishIndexLetters', () {
    test('contains I and İ separately', () {
      expect(PatientDisplayHelpers.turkishIndexLetters, contains('I'));
      expect(PatientDisplayHelpers.turkishIndexLetters, contains('İ'));
    });
  });
}
