import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/dashboard/assistant_dashboard_screen.dart';
import 'package:v2mem_clinic/features/dashboard/doctor_dashboard_screen.dart';
import 'package:v2mem_clinic/features/dashboard/nurse_dashboard_screen.dart';
import 'package:v2mem_clinic/features/dashboard/physiotherapist_dashboard_screen.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/async_physiotherapy_referral_repository_contract.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_repository_provider.dart';
import 'package:v2mem_clinic/features/physiotherapy/models/physiotherapy_referral.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/dashboard_card.dart';

class _SmokeReferralRepo implements AsyncPhysiotherapyReferralRepositoryContract {
  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async =>
      [];

  @override
  Future<List<PhysiotherapyReferral>> getAll() async => [];

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
      throw UnimplementedError();
}

void main() {
  tearDown(() {
    AuthSession.clear();
    PhysiotherapyReferralRepositoryProvider.clearTestOverrides();
    PhysiotherapyReferralRepositoryProvider.resetCache();
  });

  testWidgets('physiotherapist shows quick action list without module grid',
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
        _SmokeReferralRepo();

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PhysiotherapistDashboardScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Fizyoterapi'), findsOneWidget);
    expect(find.text('Bekleyen hastalar'), findsOneWidget);
    expect(find.textContaining('Workbench'), findsNothing);
    expect(find.text('FTR iş akışı'), findsOneWidget);
    expect(find.text('Bekleyen Yönlendirmeler'), findsOneWidget);
    expect(find.text('Klinik Özetler'), findsNothing);
    expect(find.byType(DashboardCardGrid), findsNothing);
  });

  testWidgets('doctor dashboard has no FTR referral KPI', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DoctorDashboardScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Yeni yönlendirmeler'), findsNothing);
  });

  testWidgets('assistant dashboard has no FTR referral KPI', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asst',
        role: AppRoles.assistant,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AssistantDashboardScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Yeni yönlendirmeler'), findsNothing);
  });

  testWidgets('nurse shows inventory KPI and quick actions', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'n1',
        username: 'nurse',
        displayName: 'Nurse',
        role: AppRoles.nurse,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const NurseDashboardScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Stok & Sarf'), findsOneWidget);
    expect(find.textContaining('Workbench'), findsNothing);
    expect(find.text('Düşük stok'), findsOneWidget);
    expect(find.text('Stok / Sarf'), findsOneWidget);
    expect(find.text('Görevlerim'), findsNothing);
    expect(find.text('Yeni yönlendirmeler'), findsNothing);
    expect(find.byType(DashboardCardGrid), findsNothing);
  });
}
