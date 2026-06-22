import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_list_user_messages.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_failure.dart';

void main() {
  group('ClinicalEncounterListUserMessages', () {
    test('forbidden uses safe message', () {
      expect(
        ClinicalEncounterListUserMessages.forFailure(
          ClinicalEncounterRepositoryFailure.forbidden,
        ),
        'Bu işlem için yetkiniz bulunmuyor.',
      );
    });

    test('noActiveTenant uses session message', () {
      expect(
        ClinicalEncounterListUserMessages.forFailure(
          ClinicalEncounterRepositoryFailure.noActiveTenant,
        ),
        contains('Oturum'),
      );
    });
  });
}
