import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_encounter_form_screen.dart';
import 'package:v2mem_clinic/features/clinical_encounter/widgets/clinical_encounter_form_section.dart';
import 'package:v2mem_clinic/features/patients/widgets/patient_selector_field.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_stacked_sections.dart';
import 'package:v2mem_clinic/shared/widgets/form_section_card.dart'
    as legacy_form;

void main() {
  tearDown(AuthSession.clear);

  AppUser doctorUser() => AppUser(
        id: 'u-doc',
        username: 'doctor',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      );

  Future<void> pumpForm(WidgetTester tester, {String? patientId}) async {
    AuthSession.setUser(doctorUser());

    final router = GoRouter(
      initialLocation: patientId == null
          ? '/clinical-records/new'
          : '/clinical-records/new?patientId=$patientId',
      routes: [
        GoRoute(
          path: '/clinical-records/new',
          builder: (context, state) => ClinicalEncounterFormScreen(
            patientId: Uri.parse(state.location).queryParameters['patientId'],
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('ClinicalEncounterFormScreen sections', () {
    testWidgets('shows restructured form shell for doctor', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpForm(tester, patientId: 'p1');

      expect(tester.takeException(), isNull);
      expect(find.text('Form yüklenemedi'), findsNothing);
      expect(find.text('Hasta / Muayene Kimlik'), findsOneWidget);
      expect(find.byType(ClinicalEncounterFormSection), findsWidgets);
      expect(find.byType(ClinicalStackedSections), findsWidgets);
      expect(find.byType(legacy_form.FormSectionCard), findsWidgets);
      expect(find.text('Şikayet / Hikaye'), findsWidgets);
      expect(find.text('Muayene Kaydet'), findsOneWidget);
      expect(
        find.byKey(const Key('clinical_encounter_section_index')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(
          const Key('clinical_encounter_section_chip_treatment'),
        ),
      );
      await tester.tap(
        find.byKey(
          const Key('clinical_encounter_section_chip_treatment'),
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
      expect(find.text('Özel Not', skipOffstage: false), findsWidgets);
      expect(
        find.byKey(
          const Key('clinical_encounter_section_chip_private_note'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('route patientId keeps selector locked', (tester) async {
      await pumpForm(tester, patientId: 'p1');

      final selector = tester.widget<PatientSelectorField>(
        find.byType(PatientSelectorField),
      );
      expect(selector.lockSelection, isTrue);
      expect(selector.enabled, isFalse);
      expect(selector.selectedPatientId, 'p1');

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });
  });
}
