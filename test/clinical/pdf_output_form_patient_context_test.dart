import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/features/pdf_outputs/pdf_output_form_screen.dart';
import 'package:v2mem_clinic/features/patients/data/patient_selector_data_source.dart';
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

  Future<void> pumpPdfForm(
    WidgetTester tester, {
    String? patientId,
    String? source,
    String? sourceRecordId,
  }) async {
    AuthSession.setUser(doctorUser());

    final query = <String, String>{};
    if (patientId != null) query['patientId'] = patientId;
    if (source != null) query['source'] = source;
    if (sourceRecordId != null) query['id'] = sourceRecordId;

    final uri = Uri(
      path: '/pdf-outputs/new',
      queryParameters: query.isEmpty ? null : query,
    );

    final router = GoRouter(
      initialLocation: uri.toString(),
      routes: [
        GoRoute(
          path: '/pdf-outputs/new',
          builder: (context, state) => PdfOutputFormScreen(
            patientId: Uri.parse(state.location).queryParameters['patientId'],
            source: Uri.parse(state.location).queryParameters['source'],
            sourceRecordId: Uri.parse(state.location).queryParameters['id'],
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  group('PatientSelectorDataSource', () {
    test('resolves mock patient p1 for PDF save path', () async {
      final patient = await PatientSelectorDataSource.getById('p1');
      expect(patient, isNotNull);
      expect(patient!.id, 'p1');
    });
  });

  group('PdfOutputFormScreen patient context', () {
    testWidgets('route patientId locks selector', (tester) async {
      await pumpPdfForm(tester, patientId: 'p1');

      expect(find.text('Yeni PDF Çıktı'), findsOneWidget);

      final selector = tester.widget<PatientSelectorField>(
        find.byType(PatientSelectorField),
      );
      expect(selector.lockSelection, isTrue);
      expect(selector.enabled, isFalse);
      expect(selector.selectedPatientId, 'p1');

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });

    testWidgets('clinical encounter source prefill locks patient', (
      tester,
    ) async {
      await pumpPdfForm(
        tester,
        patientId: 'p1',
        source: pdfSourceModuleClinicalEncounter,
        sourceRecordId: 'ce1',
      );

      final selector = tester.widget<PatientSelectorField>(
        find.byType(PatientSelectorField),
      );
      expect(selector.lockSelection, isTrue);
      expect(selector.selectedPatientId, 'p1');
      expect(find.textContaining('Kaynak: Muayene'), findsOneWidget);
      expect(find.textContaining('ce1'), findsNothing);
    });

    testWidgets('appointment source prefill locks patient without technical id',
        (tester) async {
      await pumpPdfForm(
        tester,
        patientId: 'p1',
        source: pdfSourceModuleAppointment,
        sourceRecordId: 'a1',
      );

      final selector = tester.widget<PatientSelectorField>(
        find.byType(PatientSelectorField),
      );
      expect(selector.lockSelection, isTrue);
      expect(selector.selectedPatientId, 'p1');
      expect(find.textContaining('Kaynak: Randevu'), findsOneWidget);
      expect(find.textContaining('a1'), findsNothing);
      expect(find.textContaining('appointmentId'), findsNothing);

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });

    testWidgets('unknown route patient shows init error', (tester) async {
      await pumpPdfForm(tester, patientId: 'missing-patient');

      expect(find.text('Form yüklenemedi'), findsOneWidget);
      expect(
        find.textContaining('Lütfen tekrar deneyin'),
        findsOneWidget,
      );
      expect(find.textContaining('Hasta kaydı bulunamadı'), findsNothing);
    });
  });
}
