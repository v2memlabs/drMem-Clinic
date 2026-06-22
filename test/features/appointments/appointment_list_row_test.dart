import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/settings/app_settings.dart';
import 'package:v2mem_clinic/features/appointments/appointment_list_screen.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository_provider.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';
import 'package:v2mem_clinic/features/appointments/widgets/appointment_clinical_list_row.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_status_legend.dart';
import 'package:v2mem_clinic/shared/widgets/data_list_card.dart';
import 'package:v2mem_clinic/shared/widgets/status_chip.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    AppointmentRepositoryProvider.resetCache();
  });

  test('AppSettings.formatTime extracts time from user format', () {
    final dt = DateTime(2026, 6, 18, 14, 32);
    expect(
      AppSettings.formatTime(dt, DateTimeFormatKind.shortTurkish),
      '14:32',
    );
    expect(
      AppSettings.formatTime(dt, DateTimeFormatKind.iso),
      '14:32',
    );
  });

  testWidgets('dimmed row for cancelled appointment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppointmentClinicalListRow(
            appointment: Appointment(
              id: 'a-cancel',
              patientId: 'p1',
              patientName: 'Ayşe Çalışkan',
              appointmentDateTime: DateTime(2026, 6, 18, 9, 30),
              durationMinutes: 30,
              type: AppointmentType.kontrol,
              status: AppointmentStatus.iptal,
              reason: '',
              controlDate: null,
            ),
            usesRemote: false,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(Opacity), findsOneWidget);
    expect(find.text('Kontrol'), findsOneWidget);
    expect(find.text('Planlandı'), findsNothing);
  });

  testWidgets('appointment list uses clinical rows and legend', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AppointmentListScreen(),
        ),
        GoRoute(
          path: '/appointments/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Detail ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(AppointmentClinicalListRow), findsWidgets);
    expect(find.byType(ClinicalStatusLegend), findsOneWidget);
    expect(find.text('Durum renkleri'), findsOneWidget);
    expect(find.byType(DataListCard), findsNothing);
    expect(find.byType(StatusChip), findsNothing);

    final row = find.byType(AppointmentClinicalListRow).first;
    await tester.tap(row);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Detail'), findsOneWidget);
  });
}
