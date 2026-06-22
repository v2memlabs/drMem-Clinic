import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/features/maintenance/maintenance_bootstrap_wizard_screen.dart';
import 'package:v2mem_clinic/features/maintenance/data/maintenance_models.dart';
import 'package:v2mem_clinic/features/maintenance/data/maintenance_provision_models.dart';

import 'maintenance_allowlist_test.dart';

Widget _wrapWithRouter(Widget child, {String initialLocation = '/'}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
    ],
    initialLocation: initialLocation,
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin step with tenant query param shows form', (tester) async {
    await tester.pumpWidget(
      _wrapWithRouter(
        const MaintenanceBootstrapWizardScreen(
          bypassGateForTesting: true,
          initialTenantId: 'a0000001-0001-4001-8001-000000000002',
          initialTenantName: 'Klinik A',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1. İlk yönetici'), findsOneWidget);
    expect(find.text('Klinik: Klinik A'), findsOneWidget);
    expect(find.text('Oluştur ve doğrula'), findsOneWidget);
    expect(find.text('1. Klinik bilgileri'), findsNothing);
  });

  testWidgets('admin step validates empty display name', (tester) async {
    await tester.pumpWidget(
      _wrapWithRouter(
        const MaintenanceBootstrapWizardScreen(
          bypassGateForTesting: true,
          initialTenantId: 't1',
          initialTenantName: 'Test',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'admin@test.com');
    await tester.tap(find.text('Oluştur ve doğrula'));
    await tester.pumpAndSettle();

    expect(find.text('Görünen ad zorunludur.'), findsOneWidget);
  });

  testWidgets('tenant dropdown shows eligible tenants only', (tester) async {
    await tester.pumpWidget(
      _wrapWithRouter(
        MaintenanceBootstrapWizardScreen(
          bypassGateForTesting: true,
          listTenantsOverride: () async => const [
            MaintenanceTenantRow(
              id: 't-active',
              name: 'Aktif Klinik',
              timezone: 'Europe/Istanbul',
              status: 'active',
            ),
            MaintenanceTenantRow(
              id: 't-suspended',
              name: 'Askıda',
              timezone: 'Europe/Istanbul',
              status: 'suspended',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1. Klinik seçimi'), findsOneWidget);
    expect(find.text('Aktif Klinik'), findsOneWidget);
    expect(find.text('Askıda'), findsNothing);
  });

  testWidgets('successful provision shows chain and password once', (tester) async {
    await tester.pumpWidget(
      _wrapWithRouter(
        MaintenanceBootstrapWizardScreen(
          bypassGateForTesting: true,
          initialTenantId: 't1',
          initialTenantName: 'Klinik',
          provisionOverride: (_) async => const MaintenanceUserProvisionResult(
            ok: true,
            operationResult: 'created',
            authUserId: 'a1',
            profileId: 'p1',
            membershipId: 'm1',
            loginUsername: 'drtest',
          ),
          bootstrapStatusOverride: ({
            required tenantId,
            profileId,
            authUserId,
          }) async =>
              const MaintenanceBootstrapStatus(
            ok: true,
            authExists: true,
            profileExists: true,
            authLinked: true,
            membershipExists: true,
            membershipActive: true,
            role: 'doctor_admin',
            tenantActive: true,
            chainOk: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'doc@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'Dr Test');
    await tester.enterText(find.byType(TextField).at(2), 'drtest');
    await tester.tap(find.text('Oluştur ve doğrula'));
    await tester.pumpAndSettle();

    expect(find.text('Login zinciri'), findsOneWidget);
    expect(find.text('Hazır'), findsWidgets);
    expect(
      find.text('Giriş bilgileri e-posta ile gönderildi'),
      findsOneWidget,
    );
    expect(find.text('TempPass-Only-Once-1234'), findsNothing);

    for (final token in maintenanceHardForbidden) {
      expect(find.textContaining(token), findsNothing);
    }
  });

  testWidgets('success step does not expose password copy controls', (tester) async {
    await tester.pumpWidget(
      _wrapWithRouter(
        MaintenanceBootstrapWizardScreen(
          bypassGateForTesting: true,
          initialTenantId: 't1',
          initialTenantName: 'Klinik',
          provisionOverride: (_) async => const MaintenanceUserProvisionResult(
            ok: true,
            operationResult: 'created',
            loginUsername: 'drtest',
          ),
          bootstrapStatusOverride: ({
            required tenantId,
            profileId,
            authUserId,
          }) async =>
              const MaintenanceBootstrapStatus(
            ok: true,
            authExists: true,
            profileExists: true,
            authLinked: true,
            membershipExists: true,
            membershipActive: true,
            tenantActive: true,
            chainOk: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'doc@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'Dr Test');
    await tester.enterText(find.byType(TextField).at(2), 'drtest');
    await tester.tap(find.text('Oluştur ve doğrula'));
    await tester.pumpAndSettle();

    expect(find.text('Parolayı kopyala'), findsNothing);
    expect(
      find.text('Giriş bilgileri e-posta ile gönderildi'),
      findsOneWidget,
    );
  });
}
