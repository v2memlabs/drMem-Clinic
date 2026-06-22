import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_subscription_repository.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_subscription_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_subscription_summary.dart';
import 'package:v2mem_clinic/features/settings/saas_subscription_settings_content.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakeSubscriptionRepo implements TenantSubscriptionRepository {
  final TenantSubscriptionSummary summary;

  _FakeSubscriptionRepo(this.summary);

  @override
  Future<TenantSubscriptionSummary> loadSummary() async => summary;
}

void main() {
  tearDown(() {
    AuthSession.clear();
    TenantSubscriptionRepositoryProvider.testOverride = null;
  });

  testWidgets('shows subscription summary without technical ids', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );
    TenantSubscriptionRepositoryProvider.testOverride = _FakeSubscriptionRepo(
      const TenantSubscriptionSummary(
        planKey: 'demo',
        planLabel: 'Demo',
        status: 'active',
        statusLabel: 'Aktif',
        seatUsed: 2,
        seatLimit: 5,
        patientCount: 8,
        patientLimit: 50,
        fromRemoteRecord: true,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SaasSubscriptionSettingsContent(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abonelik özeti'), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.text('8 / 50'), findsOneWidget);
    expect(find.textContaining('örnek'), findsNothing);
    expect(find.textContaining('plan_key'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);
  });
}
