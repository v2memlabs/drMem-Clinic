import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_list_user_messages.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository_failure.dart';

void main() {
  test('noActiveTenant message is user friendly', () {
    expect(
      PatientListUserMessages.forFailure(
        PatientRepositoryFailure.noActiveTenant,
      ),
      contains('Oturum hazır değil'),
    );
  });

  test('forbidden message is user friendly', () {
    expect(
      PatientListUserMessages.forFailure(PatientRepositoryFailure.forbidden),
      contains('yetkiniz'),
    );
  });

  test('notFound message', () {
    expect(
      PatientListUserMessages.forFailure(PatientRepositoryFailure.notFound),
      'Hasta bulunamadı.',
    );
  });
}
