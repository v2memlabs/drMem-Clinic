import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/appointments/appointment_form_screen.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_form_data_source.dart';
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

  Future<void> pumpAppointmentForm(
    WidgetTester tester, {
    String? patientId,
  }) async {
    AuthSession.setUser(doctorUser());

    final router = GoRouter(
      initialLocation: patientId == null
          ? '/appointments/new'
          : '/appointments/new?patientId=$patientId',
      routes: [
        GoRoute(
          path: '/appointments/new',
          builder: (context, state) {
            final params = Uri.parse(state.location).queryParameters;
            return AppointmentFormScreen(
              patientId: params['patientId'],
              initialTypeQuery: params['type'],
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  group('AppointmentFormDataSource.patientExists', () {
    test('returns true for mock patient p1', () async {
      expect(await AppointmentFormDataSource.patientExists('p1'), isTrue);
    });

    test('returns false for unknown id', () async {
      expect(
        await AppointmentFormDataSource.patientExists('missing-patient'),
        isFalse,
      );
    });
  });

  group('AppointmentFormScreen patient context', () {
    testWidgets('route patientId locks selector and form validates', (
      tester,
    ) async {
      await pumpAppointmentForm(tester, patientId: 'p1');

      expect(find.text('Yeni Randevu'), findsOneWidget);
      expect(find.byType(PatientSelectorField), findsOneWidget);

      final selector = tester.widget<PatientSelectorField>(
        find.byType(PatientSelectorField),
      );
      expect(selector.lockSelection, isTrue);
      expect(selector.enabled, isFalse);
      expect(selector.selectedPatientId, 'p1');

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });

    testWidgets('unknown route patient shows init error', (tester) async {
      await pumpAppointmentForm(tester, patientId: 'missing-patient');

      expect(find.text('Form yüklenemedi'), findsOneWidget);
      expect(
        find.textContaining('Hasta kaydı bulunamadı'),
        findsOneWidget,
      );
    });
  });
}
