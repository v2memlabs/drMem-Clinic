import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_encounter_form_screen.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_form_section_id.dart';
import 'package:v2mem_clinic/features/clinical_encounter/widgets/clinical_encounter_form_section_index.dart';
import 'package:v2mem_clinic/features/patients/widgets/patient_selector_field.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  AppUser user(String role) => AppUser(
        id: 'u-$role',
        username: role,
        displayName: 'Test',
        role: role,
      );

  Future<void> pumpForm(
    WidgetTester tester, {
    required String location,
  }) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/clinical-records/new',
          builder: (context, state) {
            final params = Uri.parse(state.location).queryParameters;
            return ClinicalEncounterFormScreen(
              patientId: params['patientId'],
              appointmentId: params['appointmentId'],
            );
          },
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('Clinical encounter form ergonomics', () {
    testWidgets('section index shows seven sections for doctor', (tester) async {
      AuthSession.setUser(user(AppRoles.doctor));
      await pumpForm(tester, location: '/clinical-records/new?patientId=p1');

      expect(find.byType(ClinicalEncounterFormSectionIndex), findsOneWidget);
      expect(find.text('Şikayet / Hikaye'), findsWidgets);
      expect(find.text('Özel Not'), findsWidgets);
      expect(
        find.byKey(
          Key(
            'clinical_encounter_section_chip_${ClinicalEncounterFormSectionId.privateNote}',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('non-doctor path hides private note section and chip',
        (tester) async {
      AuthSession.setUser(user(AppRoles.assistant));
      await pumpForm(tester, location: '/clinical-records/new?patientId=p1');

      expect(find.byType(ClinicalEncounterFormSectionIndex), findsOneWidget);
      expect(find.text('Özel Not'), findsNothing);
      expect(
        find.byKey(
          Key(
            'clinical_encounter_section_chip_${ClinicalEncounterFormSectionId.privateNote}',
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('sticky save labels for new and edit', (tester) async {
      AuthSession.setUser(user(AppRoles.doctor));
      await pumpForm(tester, location: '/clinical-records/new?patientId=p1');

      expect(find.text('Muayene Kaydet'), findsOneWidget);
      expect(find.text('Vazgeç'), findsOneWidget);
    });

    testWidgets('tapping section chip targets treatment section fields',
        (tester) async {
      AuthSession.setUser(user(AppRoles.doctor));
      await pumpForm(tester, location: '/clinical-records/new?patientId=p1');

      await tester.ensureVisible(
        find.byKey(
          Key(
            'clinical_encounter_section_chip_${ClinicalEncounterFormSectionId.treatment}',
          ),
        ),
      );
      await tester.tap(
        find.byKey(
          Key(
            'clinical_encounter_section_chip_${ClinicalEncounterFormSectionId.treatment}',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Enjeksiyon / İşlem Planı', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Ortez / Atel / Destek', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('diagnosis section includes ICD field in form tree', (tester) async {
      AuthSession.setUser(user(AppRoles.doctor));
      await pumpForm(tester, location: '/clinical-records/new?patientId=p1');

      expect(find.text('ICD-10 kodu', skipOffstage: false), findsOneWidget);
      expect(find.text('Ön tanı', skipOffstage: false), findsOneWidget);
      expect(find.text('Enjeksiyon / İşlem Planı', skipOffstage: false), findsOneWidget);
    });

    testWidgets('appointment handoff keeps patient lock', (tester) async {
      AuthSession.setUser(user(AppRoles.doctor));
      await pumpForm(
        tester,
        location:
            '/clinical-records/new?patientId=p1&appointmentId=apt-handoff-1',
      );

      final selector = tester.widget<PatientSelectorField>(
        find.byType(PatientSelectorField),
      );
      expect(selector.lockSelection, isTrue);
      expect(selector.selectedPatientId, 'p1');
      expect(find.textContaining('appointmentId'), findsNothing);
    });

    testWidgets('route patient lock hides quick patient create', (tester) async {
      AuthSession.setUser(user(AppRoles.doctor));
      await pumpForm(tester, location: '/clinical-records/new?patientId=p1');

      expect(
        find.byKey(const Key('clinical_encounter_quick_patient_create')),
        findsNothing,
      );

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });

    testWidgets('internalDoctorNote not shown for assistant on form route',
        (tester) async {
      AuthSession.setUser(user(AppRoles.assistant));

      final router = GoRouter(
        initialLocation: '/clinical-records/new',
        routes: [
          GoRoute(
            path: '/clinical-records/new',
            builder: (context, state) => const ClinicalEncounterFormScreen(),
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('internalDoctorNote'), findsNothing);
      expect(find.text('Özel Not'), findsNothing);
    });
  });
}
