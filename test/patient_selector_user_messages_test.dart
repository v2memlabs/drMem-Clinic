import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository_failure.dart';
import 'package:v2mem_clinic/features/patients/data/patient_selector_user_messages.dart';

void main() {
  test('generic load failure message', () {
    expect(
      PatientSelectorUserMessages.genericLoadFailure,
      'Hasta listesi yüklenemedi.',
    );
  });

  test('forbidden message', () {
    expect(
      PatientSelectorUserMessages.forFailure(
        PatientRepositoryFailure.forbidden,
      ),
      contains('yetkiniz'),
    );
  });
}
