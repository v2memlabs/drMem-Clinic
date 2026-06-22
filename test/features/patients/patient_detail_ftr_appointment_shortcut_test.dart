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
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: role,
        displayName: 'User',
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

  testWidgets('doctor sees FTR Randevusu shortcut', (tester) async {
    await pumpPatientDetail(tester, AppRoles.doctor);

    expect(find.text('FTR Randevusu'), findsOneWidget);
    expect(find.text('Yeni Randevu'), findsOneWidget);
  });

  testWidgets('assistant sees FTR Randevusu shortcut', (tester) async {
    await pumpPatientDetail(tester, AppRoles.assistant);

    expect(find.text('FTR Randevusu'), findsOneWidget);
  });

  testWidgets('nurse does not see FTR Randevusu shortcut', (tester) async {
    await pumpPatientDetail(tester, AppRoles.nurse);

    expect(find.text('FTR Randevusu'), findsNothing);
  });
}
