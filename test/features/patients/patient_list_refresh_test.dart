import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patients/data/mock_patients.dart';
import 'package:v2mem_clinic/features/patients/data/patient_list_refresh.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';
import 'package:v2mem_clinic/features/patients/patient_list_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    mockPatients.removeWhere((p) => p.id == 'refresh-test-patient');
  });

  test('PatientListRefresh tracks stale version', () {
    final baseline = PatientListRefresh.version;
    expect(PatientListRefresh.isStale(baseline), isFalse);

    PatientListRefresh.markStale();

    expect(PatientListRefresh.version, greaterThan(baseline));
    expect(PatientListRefresh.isStale(baseline), isTrue);
    expect(PatientListRefresh.isStale(PatientListRefresh.version), isFalse);
  });

  testWidgets('patient list reloads after new patient route marks stale', (
    tester,
  ) async {
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
          builder: (context, state) => const PatientListScreen(),
        ),
        GoRoute(
          path: '/patients/new',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  mockPatients.add(
                    Patient(
                      id: 'refresh-test-patient',
                      fileNumber: 'H-2099-9999',
                      firstName: 'Refresh',
                      lastName: 'Hasta',
                      phone: '+90 555 000 0000',
                      birthDate: DateTime(1990, 1, 1),
                      lastVisitDate: DateTime(2026, 6, 15),
                      primaryComplaint: 'Refresh testi',
                      bodyRegion: 'Diz',
                    ),
                  );
                  PatientListRefresh.markStale();
                  context.pop();
                },
                child: const Text('Create test patient'),
              ),
            ),
          ),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('HASTA, Refresh'), findsNothing);

    await tester.tap(find.text('Yeni Hasta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create test patient'));
    await tester.pumpAndSettle();

    expect(find.textContaining('HASTA, Refresh'), findsOneWidget);
  });
}
