import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_password_paths.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/router/auth_route_guard.dart';
import 'package:v2mem_clinic/core/session/session_readiness.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    SessionReadiness.clear();
  });

  test('unauthenticated user stays on update-password path', () {
    expect(
      AuthRouteGuard.redirectForLocation(
        '${AuthPasswordPaths.updatePasswordPath}?code=abc',
      ),
      isNull,
    );
  });
}
