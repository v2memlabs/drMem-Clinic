import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_password_setup_intent.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/router/auth_route_guard.dart';
import 'package:v2mem_clinic/core/session/session_readiness.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthPasswordSetupIntent.clear();
    AuthSession.clear();
    SessionReadiness.clear();
  });

  test('unauthenticated user can open invite accept deep link', () {
    expect(
      AuthRouteGuard.redirectForLocation(
        '/invite/accept?membership_id=a1b2c3d4-e5f6-4789-a012-3456789abcde',
      ),
      isNull,
    );
  });

  test('unauthenticated user is redirected from dashboard to login', () {
    expect(AuthRouteGuard.redirectForLocation('/doctor'), '/login');
  });

  test('authenticated user with must change password goes to update screen', () {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'staff',
        displayName: 'Staff',
        role: AppRoles.assistant,
      ),
    );
    AuthPasswordSetupIntent.markRequired();

    expect(
      AuthRouteGuard.redirectForLocation('/assistant'),
      '/auth/update-password',
    );
    expect(
      AuthRouteGuard.redirectForLocation('/auth/update-password'),
      isNull,
    );
  });
}
