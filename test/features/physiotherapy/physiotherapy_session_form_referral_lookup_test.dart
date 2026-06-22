import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_user_messages.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/features/physiotherapy/screens/physiotherapy_session_form_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

const _remoteUuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

class _FakeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    if (id != _remoteUuid) return null;
    return PhysiotherapyReferral(
      id: _remoteUuid,
      patientId: 'p1',
      patientName: 'Ayşe Yılmaz',
      referredAt: DateTime(2026, 5, 1),
      referredBy: 'Dr. Enes',
      physiotherapistName: 'Fizyoterapist A',
      diagnosisSummary: 'Menisküs dejenerasyonu',
      treatmentGoal: 'Kuvvet ve hareket kontrolü',
      precautions: 'Ağrı artışı olursa durunuz',
      allowedActivities: 'Yürüyüş',
      restrictedActivities: 'Sıçrama',
      targetReturnToSportDate: DateTime(2026, 12, 1),
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

  test('session form source does not call sync getReferralById', () {
    final source = File(
      'lib/features/physiotherapy/screens/physiotherapy_session_form_screen.dart',
    ).readAsStringSync();
    expect(source.contains('getReferralById'), isFalse);
  });

  test('session form save uses effectivePatientId fallback chain', () {
    final source = File(
      'lib/features/physiotherapy/screens/physiotherapy_session_form_screen.dart',
    ).readAsStringSync();
    expect(source.contains('final effectivePatientId ='), isTrue);
    expect(source.contains("_selectedPatientId?.trim().isNotEmpty == true"), isTrue);
    expect(source.contains("widget.patientId?.trim()"), isTrue);
    expect(source.contains("_referralPatientId?.trim()"), isTrue);
    expect(source.contains('patientId: effectivePatientId,'), isTrue);
  });

  testWidgets('remote referral id prefill without technical uuid in UI', (
    tester,
  ) async {
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();
    AuthSession.setUser(
      AppUser(
        id: 'ph1',
        username: 'physio',
        displayName: 'Fizyoterapist A',
        role: AppRoles.physiotherapist,
      ),
    );

    final router = GoRouter(
      initialLocation:
          '/physiotherapy/sessions/new?patientId=p1&referralId=$_remoteUuid',
      routes: [
        GoRoute(
          path: '/physiotherapy/sessions/new',
          builder: (context, state) {
            final params = Uri.parse(state.location).queryParameters;
            return PhysiotherapySessionFormScreen(
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
          .text(PhysiotherapyReferralLookupUserMessages.sessionLinkedBanner)
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(
      find.text(PhysiotherapyReferralLookupUserMessages.sessionLinkedBanner),
      findsOneWidget,
    );
    expect(find.textContaining(_remoteUuid), findsNothing);
    expect(find.textContaining('Kuvvet ve hareket'), findsOneWidget);
  });

  testWidgets('mock referral id prefill via async adapter', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'ph1',
        username: 'physio',
        displayName: 'Fizyoterapist A',
        role: AppRoles.physiotherapist,
      ),
    );

    final router = GoRouter(
      initialLocation:
          '/physiotherapy/sessions/new?patientId=p1&referralId=ref-001',
      routes: [
        GoRoute(
          path: '/physiotherapy/sessions/new',
          builder: (context, state) {
            final params = Uri.parse(state.location).queryParameters;
            return PhysiotherapySessionFormScreen(
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
          .text(PhysiotherapyReferralLookupUserMessages.sessionLinkedBanner)
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.textContaining('ref-001'), findsNothing);
    expect(find.textContaining('Kuvvet ve hareket'), findsOneWidget);
  });
}
