import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_encounter_form_screen.dart';
import 'package:v2mem_clinic/features/patients/widgets/patient_selector_field.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  AppUser doctorUser() => AppUser(
        id: 'u-doc',
        username: 'doctor',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      );

  Future<void> pumpNewEncounterForm(
    WidgetTester tester, {
    String? patientId,
  }) async {
    AuthSession.setUser(doctorUser());

    final location = patientId == null
        ? '/clinical-records/new'
        : '/clinical-records/new?patientId=$patientId';

    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/clinical-records/new',
          builder: (context, state) => ClinicalEncounterFormScreen(
            patientId: Uri.parse(state.location).queryParameters['patientId'],
          ),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('Quick patient create from encounter form', () {
    testWidgets('shows Yeni Hasta for new encounter without route lock',
        (tester) async {
      await pumpNewEncounterForm(tester);

      expect(
        find.byKey(const Key('clinical_encounter_quick_patient_create')),
        findsOneWidget,
      );
    });

    testWidgets('hides Yeni Hasta when route patientId locks selector',
        (tester) async {
      await pumpNewEncounterForm(tester, patientId: 'p1');

      expect(
        find.byKey(const Key('clinical_encounter_quick_patient_create')),
        findsNothing,
      );

      final selector = tester.widget<PatientSelectorField>(
        find.byType(PatientSelectorField),
      );
      expect(selector.lockSelection, isTrue);
    });

    testWidgets('quick create selects patient and preserves form text',
        (tester) async {
      await pumpNewEncounterForm(tester);

      await tester.tap(
        find.byKey(const Key('clinical_encounter_quick_patient_create')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ad *'),
        'Yeni',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Soyad *'),
        'HastaTest',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefon *'),
        '05327778899',
      );

      await tester.tap(find.text('Hastayı oluştur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      final selector = tester.widget<PatientSelectorField>(
        find.byType(PatientSelectorField),
      );
      expect(selector.selectedPatientId, isNotNull);
      expect(selector.selectedPatientPreview?.fullName, contains('HastaTest'));

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);

      expect(
        find.textContaining('hızlı oluşturuldu'),
        findsOneWidget,
      );

      await tester.enterText(
        find.bySemanticsLabel('Ana Şikayet'),
        'Diz ağrısı devam ediyor',
      );
      await tester.pump();
      expect(find.text('Diz ağrısı devam ediyor'), findsOneWidget);
    });

    testWidgets('form validates after quick create without patient error',
        (tester) async {
      await pumpNewEncounterForm(tester);

      await tester.tap(
        find.byKey(const Key('clinical_encounter_quick_patient_create')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.enterText(find.widgetWithText(TextFormField, 'Ad *'), 'Ali');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Soyad *'),
        'Veli',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefon *'),
        '05326667788',
      );

      await tester.tap(find.text('Hastayı oluştur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Ali Veli'), findsWidgets);

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });
  });
}
