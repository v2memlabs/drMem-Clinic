import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/dashboard/physiotherapist_dashboard_screen.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_list_refresh.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

PhysiotherapyReferral _referral({required String id}) {
  return PhysiotherapyReferral(
    id: id,
    patientId: 'p1',
    patientName: 'Gizli Hasta Adı',
    referredAt: DateTime(2026, 6, 1),
    referredBy: 'Dr. Test',
    physiotherapistName: 'Fizyoterapist',
    diagnosisSummary: 'Tanı özeti',
    treatmentGoal: 'Hedef',
    precautions: '',
    allowedActivities: '',
    restrictedActivities: '',
    doctorSummary: 'Gizli doktor özeti',
    notes: 'Gizli not',
    status: ReferralStatus.yeni,
  );
}

class _MutableReferralRepoForDashboard
    implements AsyncPhysiotherapyReferralRepositoryContract {
  _MutableReferralRepoForDashboard(this._items);

  List<PhysiotherapyReferral> _items;
  int getFilteredCallCount = 0;

  void setItems(List<PhysiotherapyReferral> items) {
    _items = items;
  }

  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async {
    getFilteredCallCount++;
    if (statusEnumFilter == null) {
      return List.unmodifiable(_items);
    }
    return _items.where((r) => r.status == statusEnumFilter).toList();
  }

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => List.unmodifiable(_items);

  @override
  Future<PhysiotherapyReferral?> getById(String id) async => null;

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async =>
      [];

  @override
  Future<List<PhysiotherapyReferral>> search(String query) async => [];

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async =>
      referral;

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async =>
      _items.first;
}

void main() {
  tearDown(() {
    AuthSession.clear();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
  });

  Future<void> pumpPhysioDashboard(
    WidgetTester tester, {
    required GoRouter router,
  }) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('physio workbench shows new referral KPI and quick actions',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'physio',
        displayName: 'Physio',
        role: AppRoles.physiotherapist,
      ),
    );

    PhysiotherapyReferralRepositoryProvider.testOverride =
        _MutableReferralRepoForDashboard([
      _referral(id: 'r1'),
      _referral(id: 'r2'),
    ]);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PhysiotherapistDashboardScreen(),
        ),
        GoRoute(
          path: '/physiotherapy/referrals',
          builder: (context, state) =>
              const Scaffold(body: Text('Referrals Module')),
        ),
        GoRoute(
          path: '/away',
          builder: (context, state) => const Scaffold(body: Text('Away')),
        ),
      ],
    );

    await pumpPhysioDashboard(tester, router: router);

    expect(find.text('Fizyoterapi'), findsOneWidget);
    expect(find.text('Bekleyen hastalar'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Bekleyen Yönlendirmeler'), findsOneWidget);
    expect(find.text('Randevularım'), findsOneWidget);
    expect(find.text('Seans Notları'), findsOneWidget);
    expect(find.text('Gizli Hasta Adı'), findsNothing);
    expect(find.textContaining('Gizli doktor'), findsNothing);
    expect(find.textContaining('Gizli not'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);

    await tester.tap(find.text('Bekleyen hastalar'));
    await tester.pumpAndSettle();

    expect(find.text('Referrals Module'), findsOneWidget);
  });

  testWidgets('stale refresh reloads referral KPI after return', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'physio',
        displayName: 'Physio',
        role: AppRoles.physiotherapist,
      ),
    );

    final repo = _MutableReferralRepoForDashboard([_referral(id: 'r1')]);
    PhysiotherapyReferralRepositoryProvider.testOverride = repo;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PhysiotherapistDashboardScreen(),
        ),
        GoRoute(
          path: '/away',
          builder: (context, state) => const Scaffold(body: Text('Away')),
        ),
      ],
    );

    await pumpPhysioDashboard(tester, router: router);
    expect(find.text('1'), findsOneWidget);
    final callsAfterFirstLoad = repo.getFilteredCallCount;

    router.go('/away');
    await tester.pumpAndSettle();

    repo.setItems([
      _referral(id: 'r1'),
      _referral(id: 'r2'),
      _referral(id: 'r3'),
    ]);
    PhysiotherapyReferralListRefresh.markStale();

    router.go('/');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('3'), findsOneWidget);
    expect(repo.getFilteredCallCount, greaterThan(callsAfterFirstLoad));
  });
}
