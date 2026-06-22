import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_detail_user_messages.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository_failure.dart';

void main() {
  group('AppointmentDetailUserMessages', () {
    test('noActiveTenant', () {
      expect(
        AppointmentDetailUserMessages.forFailure(
          AppointmentRepositoryFailure.noActiveTenant,
        ),
        contains('Oturum hazır değil'),
      );
    });

    test('forbidden uses appointment-specific message', () {
      expect(
        AppointmentDetailUserMessages.forFailure(
          AppointmentRepositoryFailure.forbidden,
        ),
        contains('randevu kaydına'),
      );
    });

    test('generic unknown', () {
      expect(
        AppointmentDetailUserMessages.forFailure(
          AppointmentRepositoryFailure.unknown,
        ),
        AppointmentDetailUserMessages.genericLoadFailure,
      );
    });
  });
}
