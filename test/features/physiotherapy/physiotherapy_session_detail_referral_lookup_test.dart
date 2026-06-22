import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_repository.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_session_note.dart';
import 'package:v2mem_clinic/features/physiotherapy/screens/physiotherapy_session_detail_screen.dart';

const _remoteUuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
const _sessionId = 'sess-ref-lookup-test';

class _FakeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    if (id != _remoteUuid) return null;
    return PhysiotherapyReferral(
      id: _remoteUuid,
      patientId: 'p1',
      patientName: 'Ayşe Yılmaz',
      referredAt: DateTime(2026, 4, 10),
      referredBy: 'Dr. Enes',
      physiotherapistName: 'Fizyoterapist A',
      diagnosisSummary: 'Kaynak tanı özeti',
      treatmentGoal: 'Kaynak tedavi hedefi',
      precautions: '',
      allowedActivities: '',
      restrictedActivities: '',
    );
  }

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => [];

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async =>
      [];

  @override
  Future<List<PhysiotherapyReferral>> search(String query) async => [];

  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async =>
      [];

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async =>
      referral;

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async =>
      (await getById(id))!;
}

void main() {
  tearDown(() {
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
    PhysiotherapySessionRepositoryProvider.clearTestOverrides();
    PhysiotherapySessionRepositoryProvider.resetCache();
  });

  test('session detail source does not call sync getReferralById', () {
    final source = File(
      'lib/features/physiotherapy/screens/physiotherapy_session_detail_screen.dart',
    ).readAsStringSync();
    expect(source.contains('getReferralById'), isFalse);
    expect(source.contains('getSessionNoteById'), isFalse);
  });

  testWidgets('shows Kaynak Yönlendirme for remote referral id', (
    tester,
  ) async {
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    PhysiotherapyRepository.instance.addSessionNote(
      PhysiotherapySessionNote(
        id: _sessionId,
        patientId: 'p1',
        patientName: 'Ayşe Yılmaz',
        sessionDate: DateTime(2026, 5, 20),
        physiotherapistName: 'Fizyoterapist A',
        painScore: 2,
        rangeOfMotionSummary: 'ROM iyi',
        strengthSummary: 'Orta',
        functionalAssessment: 'İyi',
        exercisesPerformed: 'Quad set',
        homeProgramCompliance: 'İyi',
        warningSigns: '-',
        returnToSportStage: ReturnToSportStage.agri_kontrolu,
        doctorNotificationNeeded: false,
        notes: '',
        referralId: _remoteUuid,
      ),
    );

    final router = GoRouter(
      initialLocation: '/physiotherapy/sessions/$_sessionId',
      routes: [
        GoRoute(
          path: '/physiotherapy/sessions/:id',
          builder: (context, state) => PhysiotherapySessionDetailScreen(
            id: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Kaynak Yönlendirme'), findsOneWidget);
    expect(find.textContaining('Kaynak tanı özeti'), findsOneWidget);
    expect(find.textContaining(_remoteUuid), findsNothing);
  });

  testWidgets('lookup failure hides source card without technical error', (
    tester,
  ) async {
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    PhysiotherapyRepository.instance.addSessionNote(
      PhysiotherapySessionNote(
        id: 'sess-missing-ref',
        patientId: 'p1',
        patientName: 'Ayşe Yılmaz',
        sessionDate: DateTime(2026, 5, 20),
        physiotherapistName: 'Fizyoterapist A',
        painScore: 2,
        rangeOfMotionSummary: 'ROM',
        strengthSummary: 'Orta',
        functionalAssessment: 'İyi',
        exercisesPerformed: 'Quad',
        homeProgramCompliance: 'İyi',
        warningSigns: '-',
        returnToSportStage: ReturnToSportStage.agri_kontrolu,
        doctorNotificationNeeded: false,
        notes: '',
        referralId: 'unknown-remote-id',
      ),
    );

    final router = GoRouter(
      initialLocation: '/physiotherapy/sessions/sess-missing-ref',
      routes: [
        GoRoute(
          path: '/physiotherapy/sessions/:id',
          builder: (context, state) => PhysiotherapySessionDetailScreen(
            id: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Kaynak Yönlendirme'), findsNothing);
    expect(find.textContaining('PostgREST'), findsNothing);
    expect(find.textContaining('unknown-remote-id'), findsNothing);
  });
}
