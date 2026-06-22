import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/appointments/appointment_form_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_state_message.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('edit init failure uses ClinicalStateMessage without exception text',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      initialLocation: '/appointments/__missing__/edit',
      routes: [
        GoRoute(
          path: '/appointments/:id/edit',
          builder: (context, state) => AppointmentFormScreen(
            appointmentId: state.pathParameters['id'],
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Form yüklenemedi'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.byType(ClinicalStateMessage), findsWidgets);
    expect(find.text('Tekrar dene'), findsOneWidget);
  });
}
