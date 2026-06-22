import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/session/session_auto_lock_controller.dart';
import 'package:v2mem_clinic/core/settings/app_settings.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  final controller = SessionAutoLockController();

  tearDown(() {
    controller.disarm();
    AuthSession.clear();
  });

  group('SessionAutoLockController', () {
    test('untilClose does not lock on timer', () async {
      AuthSession.setUser(
        AppUser(
          id: 'u1',
          username: 'doc',
          displayName: 'Doc',
          role: AppRoles.doctor,
        ),
      );
      controller.configure(AutoLockDurationKind.untilClose);
      controller.arm();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.isLocked, isFalse);
    });

    test('locks after idle timeout', () async {
      AuthSession.setUser(
        AppUser(
          id: 'u1',
          username: 'doc',
          displayName: 'Doc',
          role: AppRoles.doctor,
        ),
      );
      controller.configure(AutoLockDurationKind.min5);
      controller.arm();

      controller.lockForTest();

      expect(controller.isLocked, isTrue);
    });

    test('disarm clears lock state', () {
      AuthSession.setUser(
        AppUser(
          id: 'u1',
          username: 'doc',
          displayName: 'Doc',
          role: AppRoles.doctor,
        ),
      );
      controller.arm();
      controller.lockForTest();
      controller.disarm();

      expect(controller.isLocked, isFalse);
    });

    test('maintenance operator is not armed', () {
      AuthSession.setMaintenanceUser(
        AppUser(
          id: 'm1',
          username: 'ops',
          displayName: 'Ops',
          role: AppRoles.maintenanceOperator,
        ),
      );
      controller.configure(AutoLockDurationKind.min5);
      controller.arm();

      expect(controller.isLocked, isFalse);
    });
  });
}
