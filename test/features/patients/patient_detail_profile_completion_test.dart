import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/patients/data/patient_remote_mapper.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';
import 'package:v2mem_clinic/features/patients/widgets/patient_profile_completion_banner.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  Patient incompletePatient() => Patient(
        id: 'p-incomplete',
        fileNumber: 'H-INC-1',
        firstName: 'Eksik',
        lastName: 'Profil',
        phone: '05329998877',
        birthDate: PatientRemoteMapper.fallbackBirthDate,
        lastVisitDate: DateTime.now(),
        primaryComplaint: '',
        bodyRegion: '',
        gender: Patient.unspecifiedLabel,
        identityNumber: '',
      );

  Patient completePatient() => Patient(
        id: 'p1',
        fileNumber: 'H-2026-0001',
        firstName: 'Ahmet',
        lastName: 'Yılmaz',
        phone: '+90 532 111 2233',
        birthDate: DateTime(1978, 4, 12),
        lastVisitDate: DateTime.now(),
        primaryComplaint: 'Sol diz',
        bodyRegion: 'Diz',
        gender: 'Erkek',
        identityNumber: '11111111110',
      );

  group('PatientProfileCompletionBanner', () {
    testWidgets('shows banner for incomplete patient', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientProfileCompletionBanner(
              patient: incompletePatient(),
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Profil bilgileri eksik'), findsOneWidget);
      expect(find.text('Doğum tarihi'), findsOneWidget);
      expect(find.text('Profili tamamla'), findsOneWidget);
      expect(find.textContaining('11111111110'), findsNothing);
      expect(find.textContaining('tenant'), findsNothing);
    });

    testWidgets('hides banner for complete patient', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientProfileCompletionBanner(
              patient: completePatient(),
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Profil bilgileri eksik'), findsNothing);
    });

    testWidgets('hides complete button when onComplete is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientProfileCompletionBanner(
              patient: incompletePatient(),
            ),
          ),
        ),
      );

      expect(find.text('Profil bilgileri eksik'), findsOneWidget);
      expect(find.text('Profili tamamla'), findsNothing);
      expect(
        find.textContaining('yetkili personel'),
        findsOneWidget,
      );
    });

    testWidgets('complete button navigates to patient edit route', (tester) async {
      var navigated = false;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => PatientProfileCompletionBanner(
              patient: incompletePatient(),
              onComplete: () => context.push('/patients/p-incomplete/edit'),
            ),
          ),
          GoRoute(
            path: '/patients/:id/edit',
            builder: (context, state) {
              navigated = true;
              return const Scaffold(body: Text('Edit screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(
        find.byKey(const Key('patient_profile_completion_complete_button')),
      );
      await tester.pumpAndSettle();

      expect(navigated, isTrue);
      expect(find.text('Edit screen'), findsOneWidget);
    });
  });

  group('Role gate', () {
    test('doctor can edit patients', () {
      AuthSession.setUser(
        AppUser(
          id: 'd1',
          username: 'doc',
          displayName: 'Doc',
          role: AppRoles.doctor,
        ),
      );
      expect(AuthSession.canEditPatients, isTrue);
    });

    test('nurse cannot edit patients', () {
      AuthSession.setUser(
        AppUser(
          id: 'n1',
          username: 'nurse',
          displayName: 'Nurse',
          role: AppRoles.nurse,
        ),
      );
      expect(AuthSession.canEditPatients, isFalse);
    });
  });
}
