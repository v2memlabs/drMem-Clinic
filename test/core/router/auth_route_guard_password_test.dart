import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/router/auth_route_guard.dart';
import 'package:v2mem_clinic/core/session/session_readiness.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    SessionReadiness.clear();
  });

  test('unauthenticated user can open update password screen', () {
    expect(
      AuthRouteGuard.redirectForLocation('/auth/update-password'),
      isNull,
    );
  });

  test('unauthenticated user can open forgot password screen', () {
    expect(
      AuthRouteGuard.redirectForLocation('/auth/forgot-password'),
      isNull,
    );
  });
}
