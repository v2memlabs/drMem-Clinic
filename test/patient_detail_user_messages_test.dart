import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_detail_user_messages.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository_failure.dart';

void main() {
  test('forbidden message is patient-specific', () {
    expect(
      PatientDetailUserMessages.forFailure(PatientRepositoryFailure.forbidden),
      contains('hasta kaydına'),
    );
  });
}
