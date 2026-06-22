import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patients/patient_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  Future<void> pumpPatientDetail(WidgetTester tester, String role) async {
    final displayName = switch (role) {
      AppRoles.physiotherapist => 'Fizyoterapist A',
      AppRoles.doctor => 'Dr. Test',
      AppRoles.assistant => 'Asistan Test',
      AppRoles.nurse => 'Hemşire Test',
      _ => 'User',
    };

    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: role,
        displayName: displayName,
        role: role,
      ),
    );

    final router = GoRouter(
      initialLocation: '/patients/p1',
      routes: [
        GoRoute(
          path: '/patients/:id',
          builder: (context, state) =>
              PatientDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('doctor sees FTR randevusu in patient actions list only',
      (tester) async {
    await pumpPatientDetail(tester, AppRoles.doctor);

    expect(find.text('Yeni Muayene'), findsOneWidget);
    expect(find.text('FTR randevusu'), findsOneWidget);
    expect(find.text('Yeni randevu'), findsOneWidget);
    expect(find.text('Yeni Randevu'), findsNothing);
    expect(find.text('FTR Randevusu'), findsNothing);
  });

  testWidgets('assistant header is Yeni Randevu without FTR shortcut',
      (tester) async {
    await pumpPatientDetail(tester, AppRoles.assistant);

    expect(find.text('Yeni Randevu'), findsOneWidget);
    expect(find.text('FTR Randevusu'), findsNothing);
    expect(find.text('FTR randevusu'), findsNothing);
  });

  testWidgets('physiotherapist header is compact FTR Randevusu', (tester) async {
    await pumpPatientDetail(tester, AppRoles.physiotherapist);

    expect(find.text('FTR Randevusu'), findsOneWidget);
    expect(find.text('Yeni Randevu'), findsNothing);
  });

  testWidgets('doctor and physio see rehab summary card on patient detail',
      (tester) async {
    await pumpPatientDetail(tester, AppRoles.doctor);
    expect(find.text('Rehabilitasyon Özeti'), findsOneWidget);

    await pumpPatientDetail(tester, AppRoles.physiotherapist);
    expect(find.text('Rehabilitasyon Özeti'), findsOneWidget);
    expect(find.text('Hasta bağlamı'), findsNothing);
  });

  testWidgets('nurse does not see appointment header shortcuts', (tester) async {
    await pumpPatientDetail(tester, AppRoles.nurse);

    expect(find.text('FTR Randevusu'), findsNothing);
    expect(find.text('Yeni Randevu'), findsNothing);
    expect(find.text('Yeni Muayene'), findsNothing);
  });
}
