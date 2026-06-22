import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_count_user_messages.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository_failure.dart';

void main() {
  test('generic failure message', () {
    expect(
      PatientCountUserMessages.genericFailure,
      'Hasta sayısı alınamadı.',
    );
  });

  test('no active tenant message', () {
    expect(
      PatientCountUserMessages.forFailure(
        PatientRepositoryFailure.noActiveTenant,
      ),
      contains('Oturum'),
    );
  });
}
