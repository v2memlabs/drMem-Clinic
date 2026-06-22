import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/appointments/appointment_detail_screen.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_clinical_handoff.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_repository.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_encounter_form_screen.dart';
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

  Future<void> pumpDetail(
    WidgetTester tester, {
    required String appointmentId,
    required String role,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    AuthSession.setUser(user(role));

    final router = GoRouter(
      initialLocation: '/appointments/$appointmentId',
      routes: [
        GoRoute(
          path: '/appointments/:id',
          builder: (context, state) =>
              AppointmentDetailScreen(id: state.pathParameters['id']!),
        ),
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

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('Appointment detail Muayene Başlat CTA', () {
    testWidgets('visible for planlandi', (tester) async {
      await pumpDetail(tester, appointmentId: 'a1', role: AppRoles.doctor);
      expect(find.text(AppointmentClinicalHandoff.startEncounterLabel), findsOneWidget);
    });

    testWidgets('visible for ertelendi', (tester) async {
      await pumpDetail(tester, appointmentId: 'a9', role: AppRoles.doctor);
      expect(find.text(AppointmentClinicalHandoff.startEncounterLabel), findsOneWidget);
    });

    testWidgets('hidden for iptal', (tester) async {
      await pumpDetail(tester, appointmentId: 'a7', role: AppRoles.doctor);
      expect(find.text(AppointmentClinicalHandoff.startEncounterLabel), findsNothing);
    });

    testWidgets('hidden for gelmedi', (tester) async {
      await pumpDetail(tester, appointmentId: 'a5', role: AppRoles.doctor);
      expect(find.text(AppointmentClinicalHandoff.startEncounterLabel), findsNothing);
    });

    testWidgets('hidden for assistant', (tester) async {
      await pumpDetail(tester, appointmentId: 'a1', role: AppRoles.assistant);
      expect(find.text(AppointmentClinicalHandoff.startEncounterLabel), findsNothing);
    });

    testWidgets('hidden for physiotherapist', (tester) async {
      await pumpDetail(tester, appointmentId: 'a1', role: AppRoles.physiotherapist);
      expect(find.text(AppointmentClinicalHandoff.startEncounterLabel), findsNothing);
    });

    testWidgets('hidden for nurse', (tester) async {
      await pumpDetail(tester, appointmentId: 'a1', role: AppRoles.nurse);
      expect(find.text(AppointmentClinicalHandoff.startEncounterLabel), findsNothing);
    });
  });

  group('Handoff navigation and status', () {
    testWidgets('planlandi updates to geldi and opens locked encounter form',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final before = AppointmentRepository.instance.getById('a8');
      expect(before?.status, AppointmentStatus.planlandi);

      await pumpDetail(tester, appointmentId: 'a8', role: AppRoles.doctor);
      await tester.ensureVisible(
        find.text(AppointmentClinicalHandoff.startEncounterLabel),
      );
      await tester.tap(find.text(AppointmentClinicalHandoff.startEncounterLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      final after = AppointmentRepository.instance.getById('a8');
      expect(after?.status, AppointmentStatus.geldi);

      expect(find.byType(ClinicalEncounterFormScreen), findsOneWidget);
      final selector = tester.widget<PatientSelectorField>(
        find.byType(PatientSelectorField),
      );
      expect(selector.lockSelection, isTrue);
      expect(selector.selectedPatientId, before!.patientId);

      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);

      AppointmentRepository.instance.update(
        Appointment(
          id: before.id,
          patientId: before.patientId,
          patientName: before.patientName,
          appointmentDateTime: before.appointmentDateTime,
          durationMinutes: before.durationMinutes,
          type: before.type,
          status: AppointmentStatus.planlandi,
          reason: before.reason,
          controlDate: before.controlDate,
          notes: before.notes,
        ),
      );
    });

    testWidgets('geldi opens form without status change', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final before = AppointmentRepository.instance.getById('a2');
      expect(before?.status, AppointmentStatus.geldi);

      await pumpDetail(tester, appointmentId: 'a2', role: AppRoles.doctor);
      await tester.ensureVisible(
        find.text(AppointmentClinicalHandoff.startEncounterLabel),
      );
      await tester.tap(find.text(AppointmentClinicalHandoff.startEncounterLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      final after = AppointmentRepository.instance.getById('a2');
      expect(after?.status, AppointmentStatus.geldi);
      expect(find.byType(ClinicalEncounterFormScreen), findsOneWidget);
    });
  });
}
