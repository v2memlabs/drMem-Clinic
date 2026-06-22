import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/settings/app_settings_controller.dart';
import 'package:v2mem_clinic/core/session/session_auto_lock_controller.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/session_auto_lock_host.dart';

void main() {
  setUp(() {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'd@test.local',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );
    sessionAutoLockController.configure(
      appSettingsController.settings.autoLockDuration,
    );
    sessionAutoLockController.arm();
  });

  tearDown(() {
    AuthSession.clear();
    sessionAutoLockController.disarm();
  });

  testWidgets('paused lifecycle does not sign user out', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionAutoLockHost(
          child: const Scaffold(body: Text('app')),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(AuthSession.isLoggedIn, isTrue);
    sessionAutoLockController.disarm();
  });

  testWidgets('inactive lifecycle does not sign user out', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionAutoLockHost(
          child: const Scaffold(body: Text('app')),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(AuthSession.isLoggedIn, isTrue);
    sessionAutoLockController.disarm();
  });
}
