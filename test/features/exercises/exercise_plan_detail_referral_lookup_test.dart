import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/features/exercises/data/exercise_plan_repository.dart';
import 'package:v2mem_clinic/features/exercises/exercise_plan_detail_screen.dart';
import 'package:v2mem_clinic/features/exercises/models/exercise_item.dart';
import 'package:v2mem_clinic/features/exercises/models/exercise_plan.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';

const _remoteUuid = 'c3d4e5f6-a7b8-9012-cdef-123456789012';
const _planId = 'plan-ref-lookup-test';

class _FakeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    if (id != _remoteUuid) return null;
    return PhysiotherapyReferral(
      id: _remoteUuid,
      patientId: 'p2',
      patientName: 'Mehmet Öztürk',
      referredAt: DateTime(2026, 2, 1),
      referredBy: 'Dr. Ayşe',
      physiotherapistName: 'Fizyoterapist B',
      diagnosisSummary: 'ACL rehab tanı',
      treatmentGoal: 'ACL rehab hedef',
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
  });

  test('exercise detail source does not call sync getReferralById', () {
    final source = File(
      'lib/features/exercises/exercise_plan_detail_screen.dart',
    ).readAsStringSync();
    expect(source.contains('getReferralById'), isFalse);
  });

  testWidgets('shows Kaynak Yönlendirme for remote referral id', (
    tester,
  ) async {
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();

    ExercisePlanRepository.instance.add(
      ExercisePlan(
        id: _planId,
        patientId: 'p2',
        patientName: 'Mehmet Öztürk',
        title: 'Test Program',
        createdBy: 'Fizyoterapist B',
        createdAt: DateTime(2026, 5, 1),
        diagnosisSummary: 'Plan tanı',
        phase: ExercisePlanPhase.erkenRehabilitasyon,
        goal: 'Plan hedef',
        exercises: [
          ExerciseItem(
            id: 'e1',
            name: 'Quad',
            description: 'Set',
          ),
        ],
        homeInstructions: '',
        warnings: '',
        doctorApproved: false,
        status: ExercisePlanStatus.taslak,
        referralId: _remoteUuid,
      ),
    );

    final router = GoRouter(
      initialLocation: '/exercise-plans/$_planId',
      routes: [
        GoRoute(
          path: '/exercise-plans/:id',
          builder: (context, state) => ExercisePlanDetailScreen(
            id: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Kaynak Yönlendirme'), findsOneWidget);
    expect(find.textContaining('ACL rehab tanı'), findsOneWidget);
    expect(find.textContaining(_remoteUuid), findsNothing);
  });
}
