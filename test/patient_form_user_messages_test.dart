import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_form_user_messages.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository_failure.dart';

void main() {
  test('duplicate file number message', () {
    expect(
      PatientFormUserMessages.forFailure(
        PatientRepositoryFailure.duplicateFileNumber,
        isEdit: false,
      ),
      contains('dosya numarası'),
    );
  });

  test('create failure default message', () {
    expect(
      PatientFormUserMessages.forFailure(
        PatientRepositoryFailure.unknown,
        isEdit: false,
      ),
      'Hasta kaydı oluşturulamadı.',
    );
  });

  test('update failure default message', () {
    expect(
      PatientFormUserMessages.forFailure(
        PatientRepositoryFailure.unknown,
        isEdit: true,
      ),
      'Hasta bilgileri güncellenemedi.',
    );
  });
}
