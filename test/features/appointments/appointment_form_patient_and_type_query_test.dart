import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/appointments/appointment_form_screen.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_form_user_messages.dart';
import 'package:v2mem_clinic/features/patients/widgets/patient_selector_field.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('patientId and type query lock patient and show notice', (
    tester,
  ) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Dr',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      initialLocation: '/appointments/new?patientId=p1&type=fizikTedavi',
      routes: [
        GoRoute(
          path: '/appointments/new',
          builder: (context, state) {
            final params = Uri.parse(state.location).queryParameters;
            return AppointmentFormScreen(
              patientId: params['patientId'],
              initialTypeQuery: params['type'],
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(PatientSelectorField).evaluate().isNotEmpty) break;
    }

    final selector = tester.widget<PatientSelectorField>(
      find.byType(PatientSelectorField),
    );
    expect(selector.lockSelection, isTrue);
    expect(selector.selectedPatientId, 'p1');
    expect(
      find.text(AppointmentFormUserMessages.physiotherapySchedulingNotice),
      findsOneWidget,
    );
    expect(find.textContaining('fizikTedavi'), findsNothing);
    expect(find.textContaining('p1&type'), findsNothing);
  });
}
