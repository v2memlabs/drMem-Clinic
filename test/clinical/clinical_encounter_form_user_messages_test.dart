import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_form_user_messages.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_failure.dart';

void main() {
  group('ClinicalEncounterFormUserMessages', () {
    test('forbidden message', () {
      expect(
        ClinicalEncounterFormUserMessages.forFailure(
          ClinicalEncounterRepositoryFailure.forbidden,
          isEdit: false,
        ),
        contains('yetkiniz'),
      );
    });

    test('mock create success message', () {
      expect(
        ClinicalEncounterFormUserMessages.successMessage(
          isEdit: false,
          usesRemote: false,
        ),
        contains('mock'),
      );
    });
  });
}
