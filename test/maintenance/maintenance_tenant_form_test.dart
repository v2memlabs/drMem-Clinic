import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/features/maintenance/maintenance_tenant_form_screen.dart';
import 'package:v2mem_clinic/features/maintenance/data/maintenance_provision_models.dart';

import 'maintenance_allowlist_test.dart';

Widget _wrapWithRouter(Widget child, {String initialLocation = '/'}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/maintenance/tenants',
        builder: (context, state) => const Scaffold(
          body: Text('tenant-list'),
        ),
      ),
      GoRoute(
        path: '/maintenance/tenants/new',
        builder: (context, state) => child,
      ),
    ],
    initialLocation: initialLocation,
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty clinic name shows validation message', (tester) async {
    await tester.pumpWidget(
      _wrapWithRouter(
        const MaintenanceTenantFormScreen(bypassGateForTesting: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Klinik adı zorunludur.'), findsOneWidget);
  });

  testWidgets('uses panel sections and page header icon', (tester) async {
    await tester.pumpWidget(
      _wrapWithRouter(
        const MaintenanceTenantFormScreen(bypassGateForTesting: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_business_outlined), findsOneWidget);
    expect(find.text('Klinik Bilgisi'), findsOneWidget);
    expect(find.text('Yapılandırma'), findsOneWidget);
    expect(find.text('İptal'), findsOneWidget);
  });

  testWidgets('successful submit calls repository with correct params', (tester) async {
    MaintenanceTenantCreateRequest? captured;

    await tester.pumpWidget(
      _wrapWithRouter(
        MaintenanceTenantFormScreen(
          bypassGateForTesting: true,
          createTenantOverride: (request) async {
            captured = request;
            return const MaintenanceTenantCreateResult(
              ok: true,
              tenantId: 't-new-1',
              name: 'Test Klinik',
              status: 'active',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Test Klinik');
    await tester.enterText(find.byType(TextField).at(1), 'FTR');
    await tester.tap(find.text('Kaydet'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.name, 'Test Klinik');
    expect(captured!.specialty, 'FTR');
    expect(captured!.timezone, 'Europe/Istanbul');
    expect(captured!.status, 'active');
    expect(captured!.settingsJson, isEmpty);
  });

  testWidgets('successful submit shows SnackBar and navigates to tenant list', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithRouter(
        MaintenanceTenantFormScreen(
          bypassGateForTesting: true,
          createTenantOverride: (_) async => const MaintenanceTenantCreateResult(
            ok: true,
            tenantId: 't-new-1',
            name: 'Test Klinik',
            status: 'active',
          ),
        ),
        initialLocation: '/maintenance/tenants/new',
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Test Klinik');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Klinik oluşturuldu.'), findsOneWidget);
    expect(find.text('tenant-list'), findsOneWidget);
  });

  testWidgets('form excludes technical secrets from UI', (tester) async {
    await tester.pumpWidget(
      _wrapWithRouter(
        const MaintenanceTenantFormScreen(bypassGateForTesting: true),
      ),
    );
    await tester.pumpAndSettle();

    for (final token in maintenanceHardForbidden) {
      expect(find.textContaining(token), findsNothing);
    }
    expect(find.textContaining('tenant_id'), findsNothing);
    expect(find.textContaining('service_role'), findsNothing);
    expect(find.textContaining('password'), findsNothing);
  });
}
