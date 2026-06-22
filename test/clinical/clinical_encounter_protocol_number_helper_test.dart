import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_protocol_number_helper.dart';

void main() {
  group('ClinicalEncounterProtocolNumberHelper', () {
    test('boş listeden ilk numara', () {
      expect(
        ClinicalEncounterProtocolNumberHelper.nextFromExisting(
          const [],
          year: 2026,
        ),
        'M-2026-00001',
      );
    });

    test('mevcut sıradan devam eder', () {
      expect(
        ClinicalEncounterProtocolNumberHelper.nextFromExisting(
          ['M-2026-00001', 'M-2026-00008'],
          year: 2026,
        ),
        'M-2026-00009',
      );
    });

    test('farklı yıl sıfırdan başlar', () {
      expect(
        ClinicalEncounterProtocolNumberHelper.nextFromExisting(
          ['M-2026-00012'],
          year: 2027,
        ),
        'M-2027-00001',
      );
    });
  });
}
