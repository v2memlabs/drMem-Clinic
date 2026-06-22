import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patients/patient_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  Future<void> pumpPatientDetail(WidgetTester tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'doc',
        username: 'doc@test.com',
        displayName: 'Dr',
        role: AppRoles.doctor,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1200, 1400));

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

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('hasta detayında T.C. maskeli gösterilir, ham numara yok', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPatientDetail(tester);

    expect(find.textContaining('11*******10'), findsOneWidget);
    expect(find.textContaining('11111111110'), findsNothing);
  });
}
