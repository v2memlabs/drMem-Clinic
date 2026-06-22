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
import 'package:v2mem_clinic/core/auth/tenant_role_mapper.dart';
import 'package:v2mem_clinic/features/settings/data/mock_tenant_invite_repository.dart';
import 'package:v2mem_clinic/features/settings/data/mock_tenant_membership_repository.dart';
import 'package:v2mem_clinic/features/settings/data/mock_tenant_membership_store.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_invite_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_membership_failure.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_membership_repository.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_membership_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_membership_user.dart';
import 'package:v2mem_clinic/features/settings/users_roles_settings_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakeMembershipRepo extends MockTenantMembershipRepository {
  _FakeMembershipRepo({List<TenantMembershipUser>? seed})
      : super(
          seed: seed ??
              const [
                TenantMembershipUser(
                  membershipId: 'mem-doctor',
                  profileId: 'profile-doctor',
                  displayName: 'Dr. Test',
                  email: 'doktor@test.local',
                  loginUsername: 'drtest',
                  role: TenantRoleMapper.dbDoctorAdmin,
                  status: 'active',
                ),
                TenantMembershipUser(
                  membershipId: 'mem-assistant',
                  profileId: 'profile-assistant',
                  displayName: 'Asistan Test',
                  email: 'asistan@test.local',
                  loginUsername: 'asistant',
                  role: TenantRoleMapper.dbAssistantSecretary,
                  status: 'active',
                ),
              ],
        );
}

void main() {
  tearDown(() {
    TenantMembershipRepositoryProvider.testOverride = null;
    TenantInviteRepositoryProvider.testOverride = null;
    MockTenantMembershipStore.reset();
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<TenantMembershipUser>? members,
  }) async {
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
    if (members != null) {
      MockTenantMembershipStore.reset();
      MockTenantMembershipStore.members.addAll(members);
      TenantMembershipRepositoryProvider.testOverride =
          MockTenantMembershipRepository();
    } else {
      TenantMembershipRepositoryProvider.testOverride = _FakeMembershipRepo();
    }
    TenantInviteRepositoryProvider.testOverride = MockTenantInviteRepository();

    final router = GoRouter(
      initialLocation: '/settings/users-roles',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/settings/users-roles',
          builder: (context, state) => const UsersRolesSettingsScreen(),
          routes: [
            GoRoute(
              path: 'invite',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 1800));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  testWidgets('doctor sees member list and enabled invite action', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Dr. Test'), findsWidgets);
    expect(find.text('Asistan Test'), findsOneWidget);
    expect(find.text('Doktor'), findsWidgets);
    expect(find.text('Asistan'), findsOneWidget);
    expect(find.text('Aktif'), findsWidgets);
    expect(find.text('Kullanıcı davet et'), findsOneWidget);
    expect(find.textContaining('sonraki sürümde'), findsNothing);
    expect(find.textContaining('mem-'), findsNothing);
    expect(find.textContaining('profile-'), findsNothing);
    expect(find.textContaining('tenant-'), findsNothing);
  });

  testWidgets('self row shows cannot edit note', (tester) async {
    await pumpScreen(tester);

    expect(
      find.text('Kendi rolünüz bu ekrandan değiştirilemez.'),
      findsOneWidget,
    );
  });

  testWidgets('doctor can open login username dialog without crash', (tester) async {
    await pumpScreen(tester);

    final usernameButtons = find.widgetWithText(OutlinedButton, 'Kullanıcı adı');
    await tester.ensureVisible(usernameButtons.at(1));
    await tester.tap(usernameButtons.at(1));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('doctor can save role update for assistant', (tester) async {
    await pumpScreen(tester);

    final assistantRoleButtons = find.widgetWithText(
      OutlinedButton,
      'Rolü düzenle',
    );
    await tester.tap(assistantRoleButtons.at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hemşire').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Kaydet').last);
    await tester.pumpAndSettle();

    expect(find.text('Rol güncellendi.'), findsOneWidget);
    expect(find.text('Hemşire'), findsOneWidget);
  });

  testWidgets('invited row shows resend and cancel actions only', (tester) async {
    await pumpScreen(
      tester,
      members: const [
        TenantMembershipUser(
          membershipId: 'mem-doctor',
          displayName: 'Dr. Test',
          email: 'doktor@test.local',
          role: TenantRoleMapper.dbDoctorAdmin,
          status: 'active',
        ),
        TenantMembershipUser(
          membershipId: 'mem-invited',
          displayName: 'Davetli Kullanıcı',
          email: 'davetli@ornek.klinik',
          role: TenantRoleMapper.dbNurse,
          status: 'invited',
        ),
      ],
    );

    expect(find.text('Yeniden gönder'), findsOneWidget);
    expect(find.text('Daveti iptal et'), findsOneWidget);
    expect(find.text('Davetli'), findsOneWidget);
  });

  testWidgets('active row does not show resend or cancel', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Yeniden gönder'), findsNothing);
    expect(find.text('Daveti iptal et'), findsNothing);
  });

  testWidgets('disabled row does not show resend or cancel', (tester) async {
    await pumpScreen(
      tester,
      members: const [
        TenantMembershipUser(
          membershipId: 'mem-doctor',
          displayName: 'Dr. Test',
          email: 'doktor@test.local',
          role: TenantRoleMapper.dbDoctorAdmin,
          status: 'active',
        ),
        TenantMembershipUser(
          membershipId: 'mem-disabled',
          displayName: 'Pasif Kullanıcı',
          email: 'pasif@ornek.klinik',
          role: TenantRoleMapper.dbNurse,
          status: 'disabled',
        ),
      ],
    );

    expect(find.text('Yeniden gönder'), findsNothing);
    expect(find.text('Daveti iptal et'), findsNothing);
  });

  testWidgets('cancel invitation shows confirm and success snackbar', (tester) async {
    await pumpScreen(
      tester,
      members: const [
        TenantMembershipUser(
          membershipId: 'mem-doctor',
          displayName: 'Dr. Test',
          email: 'doktor@test.local',
          role: TenantRoleMapper.dbDoctorAdmin,
          status: 'active',
        ),
        TenantMembershipUser(
          membershipId: 'mem-invited',
          displayName: 'Davetli Kullanıcı',
          email: 'davetli@ornek.klinik',
          role: TenantRoleMapper.dbNurse,
          status: 'invited',
        ),
      ],
    );

    await tester.ensureVisible(find.text('Daveti iptal et'));
    await tester.tap(find.text('Daveti iptal et'));
    await tester.pumpAndSettle();

    expect(
      find.text('Bu davet iptal edilecek. Kullanıcı hesabı silinmeyecek.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Daveti iptal et').last);
    await tester.pumpAndSettle();

    expect(find.text('Davet iptal edildi.'), findsOneWidget);
    expect(find.text('Pasif'), findsOneWidget);
  });

  testWidgets('resend invitation shows confirm and success snackbar', (tester) async {
    await pumpScreen(
      tester,
      members: const [
        TenantMembershipUser(
          membershipId: 'mem-doctor',
          displayName: 'Dr. Test',
          email: 'doktor@test.local',
          role: TenantRoleMapper.dbDoctorAdmin,
          status: 'active',
        ),
        TenantMembershipUser(
          membershipId: 'mem-invited',
          displayName: 'Davetli Kullanıcı',
          email: 'davetli@ornek.klinik',
          role: TenantRoleMapper.dbNurse,
          status: 'invited',
        ),
      ],
    );

    await tester.ensureVisible(find.text('Yeniden gönder'));
    await tester.tap(find.text('Yeniden gönder'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Gönder').last);
    await tester.pumpAndSettle();

    expect(find.text('Davet yeniden gönderildi.'), findsOneWidget);
  });

  testWidgets('empty state when no members', (tester) async {
    TenantMembershipRepositoryProvider.testOverride =
        MockTenantMembershipRepository(seed: const []);

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

    final router = GoRouter(
      initialLocation: '/settings/users-roles',
      routes: [
        GoRoute(
          path: '/settings/users-roles',
          builder: (context, state) => const UsersRolesSettingsScreen(),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 1800));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      find.text('Bu klinikte listelenecek kullanıcı bulunamadı.'),
      findsOneWidget,
    );
  });

  testWidgets('error state on load failure', (tester) async {
    TenantMembershipRepositoryProvider.testOverride =
        _ForbiddenMembershipRepo();

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

    final router = GoRouter(
      initialLocation: '/settings/users-roles',
      routes: [
        GoRoute(
          path: '/settings/users-roles',
          builder: (context, state) => const UsersRolesSettingsScreen(),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 1800));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Bu işlem için yetkiniz yok.'), findsOneWidget);
  });
}

class _ForbiddenMembershipRepo extends MockTenantMembershipRepository {
  @override
  Future<List<TenantMembershipUser>> listCurrentTenantMembers() async {
    throw TenantMembershipRepositoryException(
      TenantMembershipFailure.forbidden,
      'Bu işlem için yetkiniz yok.',
    );
  }
}
