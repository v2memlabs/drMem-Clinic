import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/features/physiotherapy/screens/physiotherapy_referral_detail_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/detail_action_labels.dart';

const _referralId = 'ref-ftr-appt-cta';

class _FakeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    if (id != _referralId) return null;
    return PhysiotherapyReferral(
      id: _referralId,
      patientId: 'p1',
      patientName: 'Test Hasta',
      referredAt: DateTime(2026, 5, 1),
      referredBy: 'Dr',
      physiotherapistName: 'Fizyo',
      diagnosisSummary: 'Tanı',
      treatmentGoal: 'Hedef',
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
    AuthSession.clear();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
  });

  Future<void> pumpDetail(WidgetTester tester, String role) async {
    PhysiotherapyReferralRepositoryProvider.testOverride = _FakeReferralRepo();
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: role,
        displayName: 'User',
        role: role,
      ),
    );

    final router = GoRouter(
      initialLocation: '/physiotherapy/referrals/$_referralId',
      routes: [
        GoRoute(
          path: '/physiotherapy/referrals/:id',
          builder: (context, state) => PhysiotherapyReferralDetailScreen(
            id: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  testWidgets('doctor sees Fizik Tedavi Randevusu Planla CTA', (tester) async {
    await pumpDetail(tester, AppRoles.doctor);

    expect(
      find.text(DetailActionLabels.physiotherapyAppointmentPlan),
      findsOneWidget,
    );
    expect(find.textContaining(_referralId), findsNothing);
  });

  testWidgets('physiotherapist sees appointment plan CTA for pending referral', (
    tester,
  ) async {
    await pumpDetail(tester, AppRoles.physiotherapist);

    expect(
      find.text(DetailActionLabels.physiotherapyAppointmentPlan),
      findsOneWidget,
    );
  });
}
