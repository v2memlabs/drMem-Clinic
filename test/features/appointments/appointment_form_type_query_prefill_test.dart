import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/appointments/appointment_form_screen.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_form_user_messages.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_type_query_parser.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  Future<void> pumpForm(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Dr',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      initialLocation: initialLocation,
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
      if (find.text('Randevu Türü').evaluate().isNotEmpty) return;
    }
  }

  testWidgets('type=fizikTedavi shows scheduling notice', (tester) async {
    await pumpForm(tester, initialLocation: '/appointments/new?type=fizikTedavi');

    expect(
      AppointmentTypeQueryParser.fromQuery('fizikTedavi'),
      AppointmentType.fizikTedavi,
    );
    expect(
      find.text(AppointmentFormUserMessages.physiotherapySchedulingNotice),
      findsOneWidget,
    );
  });

  testWidgets('type=physiotherapy alias shows scheduling notice', (tester) async {
    await pumpForm(tester, initialLocation: '/appointments/new?type=physiotherapy');

    expect(
      AppointmentTypeQueryParser.fromQuery('physiotherapy'),
      AppointmentType.fizikTedavi,
    );
    expect(
      find.text(AppointmentFormUserMessages.physiotherapySchedulingNotice),
      findsOneWidget,
    );
  });

  testWidgets('unknown type has no scheduling notice', (tester) async {
    await pumpForm(tester, initialLocation: '/appointments/new?type=invalid');

    expect(AppointmentTypeQueryParser.fromQuery('invalid'), isNull);
    expect(
      find.text(AppointmentFormUserMessages.physiotherapySchedulingNotice),
      findsNothing,
    );
  });
}
