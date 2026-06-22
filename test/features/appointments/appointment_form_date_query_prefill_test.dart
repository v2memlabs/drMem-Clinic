import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/appointments/appointment_form_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('date query prefills schedule date label', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Dr',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      initialLocation: '/appointments/new?date=2026-06-15',
      routes: [
        GoRoute(
          path: '/appointments/new',
          builder: (context, state) {
            final params = Uri.parse(state.location).queryParameters;
            return AppointmentFormScreen(
              patientId: params['patientId'],
              initialTypeQuery: params['type'],
              initialDateQuery: params['date'],
            );
          },
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('15 Haziran 2026'), findsOneWidget);
  });
}
