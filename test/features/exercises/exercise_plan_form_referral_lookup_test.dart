import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/exercises/exercise_plan_form_screen.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_user_messages.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

const _remoteUuid = 'b2c3d4e5-f6a7-8901-bcde-f12345678901';

class _FakeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    if (id != _remoteUuid) return null;
    return PhysiotherapyReferral(
      id: _remoteUuid,
      patientId: 'p2',
      patientName: 'Mehmet Öztürk',
      referredAt: DateTime(2026, 3, 1),
      referredBy: 'Dr. Ayşe',
      physiotherapistName: 'Fizyoterapist B',
      diagnosisSummary: 'Ön çapraz bağ rehabilitasyonu',
      treatmentGoal: 'Stabilite kazanımı',
      precautions: 'Pivot yasak',
      allowedActivities: 'Bisiklet',
      restrictedActivities: 'Koşu',
      targetReturnToSportDate: DateTime(2027, 1, 1),
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
    AuthSession.clear();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
  });

  test('exercise form source does not call sync getReferralById', () {
    final source = File(
      'lib/features/exercises/exercise_plan_form_screen.dart',
    ).readAsStringSync();
    expect(source.contains('getReferralById'), isFalse);
  });

  test('exercise form save uses effectivePatientId fallback chain', () {
    final source = File(
      'lib/features/exercises/exercise_plan_form_screen.dart',
    ).readAsStringSync();
    expect(source.contains('final effectivePatientId ='), isTrue);
    expect(source.contains('selectedPatientId?.trim().isNotEmpty == true'), isTrue);
    expect(source.contains("widget.patientId?.trim()"), isTrue);
    expect(source.contains("_referralPatientId?.trim()"), isTrue);
    expect(source.contains('patientId: effectivePatientId,'), isTrue);
  });

  testWidgets('remote referral prefill without technical uuid', (
    tester,
  ) async {
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();
    AuthSession.setUser(
      AppUser(
        id: 'ph1',
        username: 'physio',
        displayName: 'Fizyoterapist B',
        role: AppRoles.physiotherapist,
      ),
    );

    final router = GoRouter(
      initialLocation:
          '/exercise-plans/new?patientId=p2&referralId=$_remoteUuid',
      routes: [
        GoRoute(
          path: '/exercise-plans/new',
          builder: (context, state) {
            final params = Uri.parse(state.location).queryParameters;
            return ExercisePlanFormScreen(
              patientId: params['patientId'],
              referralId: params['referralId'],
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
          .text(PhysiotherapyReferralLookupUserMessages.exerciseLinkedBanner)
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(
      find.text(PhysiotherapyReferralLookupUserMessages.exerciseLinkedBanner),
      findsOneWidget,
    );
    expect(find.textContaining(_remoteUuid), findsNothing);
    expect(find.textContaining('Ön çapraz bağ'), findsOneWidget);
    expect(find.textContaining('Stabilite kazanımı'), findsOneWidget);
    expect(find.textContaining('Egzersiz Programı — Mehmet'), findsOneWidget);
  });
}
