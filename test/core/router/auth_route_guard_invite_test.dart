import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/router/auth_route_guard.dart';
import 'package:v2mem_clinic/core/session/session_readiness.dart';

void main() {
  tearDown(() {
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
}
