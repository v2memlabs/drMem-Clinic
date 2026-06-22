import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_encounter/widgets/patient_scoped_clinical_encounter_row.dart';
import 'package:v2mem_clinic/features/patients/patient_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/status_chip.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    ClinicalEncounterRepositoryProvider.testOverride = null;
    ClinicalEncounterRepositoryProvider.resetCache();
  });

  Future<void> pumpPatientDetail(
    WidgetTester tester, {
    required String patientId,
    required String role,
  }) async {
    AuthSession.setUser(
      AppUser(
        id: 'u-$role',
        username: role,
        displayName: role == AppRoles.doctor ? 'Dr. Mehmet Yalçınozan' : 'Test',
        role: role,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1800, 1400));

    final router = GoRouter(
      initialLocation: '/patients/$patientId',
      routes: [
        GoRoute(
          path: '/patients/:id',
          builder: (context, state) =>
              PatientDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/clinical-records/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('Encounter detail')),
        ),
        GoRoute(
          path: '/clinical-records',
          builder: (context, state) =>
              const Scaffold(body: Text('Encounter list')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('doctor patient detail shows scoped clinical rows', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPatientDetail(tester, patientId: 'p1', role: AppRoles.doctor);

    expect(find.text('Muayene Kayıtları'), findsOneWidget);
    expect(find.byType(PatientScopedClinicalEncounterRow), findsWidgets);

    expect(find.text('Ahmet Yılmaz'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PatientScopedClinicalEncounterRow),
        matching: find.text('Ahmet Yılmaz'),
      ),
      findsNothing,
    );

    expect(find.textContaining('İlk Muayene'), findsWidgets);
    expect(find.textContaining('Tanı:'), findsWidgets);
    expect(find.textContaining('Aktivite modifikasyonu'), findsWidgets);
    expect(find.text('Tamamlandı'), findsWidgets);
    expect(find.byType(StatusChip), findsNothing);

    expect(find.textContaining('internalDoctorNote'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);
    expect(find.textContaining('ce1'), findsNothing);
  });

  testWidgets('tap navigates to encounter detail', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPatientDetail(tester, patientId: 'p1', role: AppRoles.doctor);

    final row = find.byType(PatientScopedClinicalEncounterRow).first;
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('Encounter detail'), findsOneWidget);
  });

  testWidgets('kontrol planlandi patient row has muted status not chip', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPatientDetail(tester, patientId: 'p8', role: AppRoles.doctor);

    expect(find.text('Kontrol Planlandı'), findsWidgets);
    expect(find.byType(StatusChip), findsNothing);
  });

  testWidgets('assistant does not see patient scoped clinical rows', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPatientDetail(tester, patientId: 'p1', role: AppRoles.assistant);

    expect(find.byType(PatientScopedClinicalEncounterRow), findsNothing);
    expect(find.text('Muayene Kayıtları'), findsNothing);
  });
}
