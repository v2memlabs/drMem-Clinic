import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/navigation/app_nav_config.dart';
import 'package:v2mem_clinic/features/clinical_encounter/clinical_encounter_list_screen.dart';
import 'package:v2mem_clinic/features/settings/settings_subpage_scaffold.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/filter_bar.dart';

void main() {
  tearDown(AuthSession.clear);

  group('app_nav_config', () {
    test('doctor core nav is flat without Klinik group title', () {
      AuthSession.setUser(
        AppUser(
          id: 'd1',
          username: 'doc',
          displayName: 'Doc',
          role: AppRoles.doctor,
        ),
      );

      final sections = buildAppNavSections();
      expect(sections.any((s) => s.title == 'Klinik'), isFalse);

      final core = sections.first;
      expect(core.hideTitle, isTrue);
      final labels = core.items.map((i) => i.label).toList();
      final surgeryIdx = labels.indexOf('Ameliyat / İşlem');
      final postOpIdx = labels.indexOf('Post-op Takip');
      expect(surgeryIdx, greaterThan(-1));
      expect(postOpIdx, greaterThan(surgeryIdx));

      final ftrLabels = sections
          .expand((s) => s.items)
          .where((i) => i.route.startsWith('/physiotherapy'))
          .map((i) => i.label)
          .toList();
      expect(ftrLabels, ['FTR Yönlendirme']);
    });
  });

  testWidgets('clinical list filters collapsed by default', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ClinicalEncounterListScreen(),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Filtreler'), findsOneWidget);
    expect(find.text('Yeni Muayene'), findsOneWidget);
    expect(find.text('Başvuru tipi'), findsNothing);

    await tester.tap(find.text('Filtreler'));
    await tester.pumpAndSettle();
    expect(find.text('Başvuru tipi'), findsOneWidget);
  });

  testWidgets('tablet width FilterBar keeps search and CTA on one row', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            searchHint: 'Ara',
            onSearchChanged: (_) {},
            trailing: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Hasta'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(FilterBar), findsOneWidget);
    expect(find.text('Yeni Hasta'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsWidgets);
  });

  testWidgets('settings subpage uses compact back not Ayarlara dön text',
      (tester) async {
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
          path: '/settings',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/settings/test',
          builder: (context, state) => const SettingsSubpageScaffold(
            title: 'Test Ayar',
            icon: Icons.tune,
            children: [Text('İçerik')],
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/settings/test');
    await tester.pumpAndSettle();

    expect(find.textContaining('Ayarlar\'a dön'), findsNothing);
    expect(find.byTooltip('Geri'), findsOneWidget);
  });
}
