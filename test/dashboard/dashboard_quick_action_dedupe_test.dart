import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/navigation/app_nav_config.dart';
import 'package:v2mem_clinic/features/dashboard/assistant_dashboard_screen.dart';
import 'package:v2mem_clinic/features/dashboard/data/dashboard_intentional_quick_routes.dart';
import 'package:v2mem_clinic/features/dashboard/doctor_dashboard_screen.dart';
import 'package:v2mem_clinic/features/dashboard/nurse_dashboard_screen.dart';
import 'package:v2mem_clinic/features/dashboard/physiotherapist_dashboard_screen.dart';
import 'package:v2mem_clinic/features/dashboard/widgets/dashboard_quick_action_list.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/dashboard_card.dart';

void main() {
  tearDown(AuthSession.clear);

  List<String> _quickActionLabels(WidgetTester tester) {
    return tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text?)?.data ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> pumpDashboard(
    WidgetTester tester,
    Widget screen,
  ) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => screen)],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  test('sidebar overlap whitelist covers intentional dashboard routes', () {
    for (final route in [
      ...DashboardIntentionalQuickRoutes.doctor,
      ...DashboardIntentionalQuickRoutes.assistant,
      ...DashboardIntentionalQuickRoutes.createRoutes,
    ]) {
      expect(DashboardIntentionalQuickRoutes.isIntentionalOverlap(route), isTrue);
    }
    expect(DashboardIntentionalQuickRoutes.isIntentionalOverlap('/patients'), isFalse);
  });

  testWidgets('doctor quick actions respect max and dedupe sidebar', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    await pumpDashboard(tester, const DoctorDashboardScreen());

    final labels = _quickActionLabels(tester);
    expect(labels.length, lessThanOrEqualTo(4));
    expect(labels, contains('Yeni Muayene'));
    expect(labels, contains('Yeni Randevu'));
    expect(labels, contains('PDF Çıktı'));
    expect(labels, isNot(contains('Hastalar')));
    expect(labels, isNot(contains('Muayene Kayıtları')));

    final navRoutes = visibleNavRoutes().toSet();
    for (final label in labels) {
      // Labels only — route overlap checked via intentional list in unit test above.
      expect(label, isNotEmpty);
    }
    expect(navRoutes.contains('/patients'), isTrue);
    expect(find.text('Hastalar'), findsNothing);
  });

  testWidgets('assistant quick actions operational and no full clinical',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asst',
        role: AppRoles.assistant,
      ),
    );

    await pumpDashboard(tester, const AssistantDashboardScreen());

    final labels = _quickActionLabels(tester);
    expect(labels.length, lessThanOrEqualTo(4));
    expect(labels, contains('Yeni Randevu'));
    expect(labels, contains('KVKK / Onam'));
    expect(labels, contains('Ödeme'));
    expect(labels, contains('Dosya Yükle'));
    expect(labels, isNot(contains('Hastalar')));
    expect(labels, isNot(contains('Randevular')));
    expect(labels, isNot(contains('Tanı / Ön Tanı Özeti')));
    expect(find.text('Muayene Kayıtları'), findsNothing);
    expect(find.text('Yeni Muayene'), findsNothing);
  });

  testWidgets('physio quick actions max 3 without clinical summaries',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'physio',
        displayName: 'Physio',
        role: AppRoles.physiotherapist,
      ),
    );

    await pumpDashboard(tester, const PhysiotherapistDashboardScreen());

    final labels = _quickActionLabels(tester);
    expect(labels.length, lessThanOrEqualTo(3));
    expect(labels, contains('Yönlendirmeler'));
    expect(labels, contains('Seans Notları'));
    expect(labels, contains('Egzersiz Programları'));
    expect(labels, isNot(contains('Klinik Özetler')));
  });

  testWidgets('nurse quick actions stock only without placeholder card',
      (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'n1',
        username: 'nurse',
        displayName: 'Nurse',
        role: AppRoles.nurse,
      ),
    );

    await pumpDashboard(tester, const NurseDashboardScreen());

    final labels = _quickActionLabels(tester);
    expect(labels.length, lessThanOrEqualTo(2));
    expect(labels, contains('Stok / Sarf'));
    expect(labels, isNot(contains('Hastalar')));
    expect(find.text('Görevlerim'), findsNothing);
    expect(find.byType(DashboardCard), findsNothing);
  });

  test('filterAllowed respects max order truncation', () {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );
    final source = [
      const DashboardQuickAction(
        icon: Icons.add,
        label: 'A1',
        route: '/clinical-records/new',
      ),
      const DashboardQuickAction(
        icon: Icons.add,
        label: 'A2',
        route: '/appointments/new',
      ),
      const DashboardQuickAction(
        icon: Icons.add,
        label: 'A3',
        route: '/pdf-outputs',
      ),
      const DashboardQuickAction(
        icon: Icons.add,
        label: 'A4',
        route: '/patients',
      ),
      const DashboardQuickAction(
        icon: Icons.add,
        label: 'A5',
        route: '/clinical-records',
      ),
    ];
    final trimmed = DashboardQuickActionList.filterAllowed(source, max: 4);
    expect(trimmed.length, 4);
    expect(trimmed.first.label, 'A1');
    expect(trimmed.last.label, 'A4');
  });
}
