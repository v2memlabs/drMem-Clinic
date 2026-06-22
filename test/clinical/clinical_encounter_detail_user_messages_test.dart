import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_detail_user_messages.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_failure.dart';

void main() {
  group('ClinicalEncounterDetailUserMessages', () {
    test('forbidden uses safe message', () {
      expect(
        ClinicalEncounterDetailUserMessages.forFailure(
          ClinicalEncounterRepositoryFailure.forbidden,
        ),
        contains('yetkiniz'),
      );
    });

    test('notFound message', () {
      expect(
        ClinicalEncounterDetailUserMessages.forFailure(
          ClinicalEncounterRepositoryFailure.notFound,
        ),
        'Muayene kaydı bulunamadı.',
      );
    });
  });
}
