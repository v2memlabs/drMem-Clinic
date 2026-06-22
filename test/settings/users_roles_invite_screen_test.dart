import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/features/settings/data/mock_tenant_invite_repository.dart';
import 'package:v2mem_clinic/features/settings/data/mock_tenant_membership_store.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_invite_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/users_roles_invite_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    TenantInviteRepositoryProvider.testOverride = null;
    MockTenantMembershipStore.reset();
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'profile-doctor',
        username: 'd@test.local',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 'tenant-1', name: 'Klinik'),
        membership: const Membership(
          id: 'mem-doctor',
          tenantId: 'tenant-1',
          userId: 'profile-doctor',
          role: AppRoles.doctor,
        ),
        profile: const UserProfile(userId: 'profile-doctor', displayName: 'Dr. Test'),
      ),
    );
    TenantInviteRepositoryProvider.testOverride = MockTenantInviteRepository();

    final router = GoRouter(
      initialLocation: '/settings/users-roles/invite',
      routes: [
        GoRoute(
          path: '/settings/users-roles',
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: 'invite',
              builder: (context, state) => const UsersRolesInviteScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('invite form renders fields and role labels', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Kullanıcı Davet Et'), findsWidgets);
    expect(find.text('E-posta'), findsOneWidget);
    expect(find.text('Görünen ad'), findsOneWidget);
    expect(find.text('Giriş kullanıcı adı'), findsOneWidget);
    expect(find.text('Rol'), findsOneWidget);
    expect(find.text('Davet gönder'), findsOneWidget);
    expect(find.text('Doktor'), findsWidgets);
    expect(find.text('Asistan'), findsWidgets);
  });

  testWidgets('validation shows safe error for empty email', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Davet gönder'));
    await tester.pumpAndSettle();

    expect(find.text('Geçerli bir e-posta adresi girin.'), findsOneWidget);
  });

  testWidgets('successful invite returns to previous route', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField).at(0), 'yeni@test.local');
    await tester.enterText(find.byType(TextField).at(1), 'Yeni Kullanıcı');
    await tester.tap(find.text('Davet gönder'));
    await tester.pumpAndSettle();

    expect(find.text('Kullanıcı Davet Et'), findsNothing);
    expect(
      MockTenantMembershipStore.members.any(
        (m) => m.email == 'yeni@test.local' && m.status == 'invited',
      ),
      isTrue,
    );
  });
}
