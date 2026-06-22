import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_form_user_messages.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository_failure.dart';

void main() {
  group('AppointmentFormUserMessages', () {
    test('create failure messages', () {
      expect(
        AppointmentFormUserMessages.forFailure(
          AppointmentRepositoryFailure.unknown,
          isEdit: false,
        ),
        'Randevu oluşturulamadı.',
      );
    });

    test('update failure messages', () {
      expect(
        AppointmentFormUserMessages.forFailure(
          AppointmentRepositoryFailure.unknown,
          isEdit: true,
        ),
        'Randevu bilgileri güncellenemedi.',
      );
    });

    test('patientNotFound', () {
      expect(
        AppointmentFormUserMessages.forFailure(
          AppointmentRepositoryFailure.patientNotFound,
          isEdit: false,
        ),
        contains('hasta'),
      );
    });

    test('invalidDateTime', () {
      expect(
        AppointmentFormUserMessages.forFailure(
          AppointmentRepositoryFailure.invalidDateTime,
          isEdit: false,
        ),
        contains('Geçersiz'),
      );
    });

    test('success messages', () {
      expect(
        AppointmentFormUserMessages.successMessage(isEdit: false),
        'Randevu kaydedildi.',
      );
      expect(
        AppointmentFormUserMessages.successMessage(isEdit: true),
        'Randevu güncellendi.',
      );
    });
  });
}
