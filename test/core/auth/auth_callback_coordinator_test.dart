import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:v2mem_clinic/core/auth/auth_callback_coordinator.dart';
import 'package:v2mem_clinic/core/auth/auth_password_paths.dart';
import 'package:v2mem_clinic/core/auth/auth_password_setup_intent.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/auth/pending_invitation_store.dart';
import 'package:v2mem_clinic/core/auth/startup_session_purge.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

Session _testSession() {
  return Session(
    accessToken: 't',
    tokenType: 'bearer',
    user: User(
      id: 'u',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    ),
  );
}

void main() {
  late GoRouter router;
  String? lastLocation;

  setUp(() {
    lastLocation = null;
    router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: AuthPasswordPaths.updatePasswordPath,
          builder: (_, __) => const SizedBox.shrink(),
        ),
      ],
      redirect: (context, state) {
        lastLocation = state.matchedLocation;
        return null;
      },
    );
    StartupSessionPurge.resetForTest();
  });

  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    PendingInvitationStore.clear();
    AuthPasswordSetupIntent.clear();
    StartupSessionPurge.resetForTest();
  });

  test('initialSession does not bootstrap or navigate', () {
    AuthCallbackCoordinator.handleAuthStateForTest(
      router,
      const AuthState(AuthChangeEvent.initialSession, null),
    );
    expect(lastLocation, isNull);
    expect(AuthSession.isLoggedIn, isFalse);
  });

  test('tokenRefreshed does not clear session', () {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'd@test.local',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );
    AuthCallbackCoordinator.handleAuthStateForTest(
      router,
      AuthState(
        AuthChangeEvent.tokenRefreshed,
        _testSession(),
      ),
    );
    expect(AuthSession.isLoggedIn, isTrue);
  });

  test('signedOut clears local session state', () {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'd@test.local',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 't1', name: 'Klinik'),
        membership: const Membership(
          id: 'm1',
          tenantId: 't1',
          userId: 'p1',
          role: AppRoles.doctor,
        ),
        profile: const UserProfile(userId: 'p1', displayName: 'Doktor'),
      ),
    );

    AuthCallbackCoordinator.handleAuthStateForTest(
      router,
      const AuthState(AuthChangeEvent.signedOut, null),
    );

    expect(AuthSession.isLoggedIn, isFalse);
    expect(ActiveTenantContextStore.current, isNull);
  });

  test('signedIn before purge completes is ignored', () {
    PendingInvitationStore.setMembershipId('a1b2c3d4-e5f6-4789-a012-3456789abcde');
    AuthCallbackCoordinator.handleAuthStateForTest(
      router,
      AuthState(
        AuthChangeEvent.signedIn,
        _testSession(),
      ),
    );
    expect(lastLocation, isNull);
  });

  test('signedIn after purge with pending invitation routes to password setup', () async {
    await StartupSessionPurge.run();
    PendingInvitationStore.setMembershipId('a1b2c3d4-e5f6-4789-a012-3456789abcde');

    AuthCallbackCoordinator.handleAuthStateForTest(
      router,
      AuthState(
        AuthChangeEvent.signedIn,
        _testSession(),
      ),
    );

    expect(AuthPasswordSetupIntent.isRequired, isTrue);
  });
}
