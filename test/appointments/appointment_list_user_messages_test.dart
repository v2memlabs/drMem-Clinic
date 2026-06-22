import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_list_user_messages.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository_failure.dart';

void main() {
  group('AppointmentListUserMessages', () {
    test('noActiveTenant', () {
      expect(
        AppointmentListUserMessages.forFailure(
          AppointmentRepositoryFailure.noActiveTenant,
        ),
        contains('Oturum hazır değil'),
      );
    });

    test('forbidden', () {
      expect(
        AppointmentListUserMessages.forFailure(
          AppointmentRepositoryFailure.forbidden,
        ),
        contains('yetkiniz'),
      );
    });

    test('generic unknown', () {
      expect(
        AppointmentListUserMessages.forFailure(
          AppointmentRepositoryFailure.unknown,
        ),
        AppointmentListUserMessages.genericLoadFailure,
      );
    });
  });
}
