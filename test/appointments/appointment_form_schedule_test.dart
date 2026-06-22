import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/appointments/appointment_form_screen.dart';
import 'package:v2mem_clinic/features/appointments/widgets/appointment_schedule_section.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  AppUser doctorUser() => AppUser(
        id: 'u-doc',
        username: 'doctor',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      );

  Future<void> pumpForm(WidgetTester tester) async {
    AuthSession.setUser(doctorUser());

    final router = GoRouter(
      initialLocation: '/appointments/new',
      routes: [
        GoRoute(
          path: '/appointments/new',
          builder: (context, state) => const AppointmentFormScreen(),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('appointment_schedule_section')).evaluate().isNotEmpty) {
        return;
      }
    }
  }

  group('AppointmentScheduleSection.gridColumnCount', () {
    test('scales columns with width', () {
      expect(AppointmentScheduleSection.gridColumnCount(360), 4);
      expect(AppointmentScheduleSection.gridColumnCount(500), 5);
      expect(AppointmentScheduleSection.gridColumnCount(650), 6);
      expect(AppointmentScheduleSection.gridColumnCount(800), 7);
      expect(AppointmentScheduleSection.gridColumnCount(1000), 8);
    });
  });

  group('AppointmentFormScreen schedule', () {
    testWidgets('shows compact schedule without nested section titles', (
      tester,
    ) async {
      await pumpForm(tester);

      expect(find.byKey(const Key('appointment_schedule_section')), findsOneWidget);
      expect(find.text('Müsait saatler'), findsNothing);
      expect(find.text('Randevu zamanı'), findsNothing);
      expect(find.text('Hasta ve Zaman'), findsNothing);
      expect(find.text('Randevu Detayı'), findsNothing);
      expect(find.text('Randevu Türü'), findsOneWidget);
      expect(find.text('Durum'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GridView), findsOneWidget);
    });

  });
}
