import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final script = File(
    'scripts/staging/settings_user_invitation_v2e_deeplink_smoke_checks.sql',
  );
  final runner = File('scripts/staging/run_settings_invitation_v2e_smoke.ps1');

  test('v2e deep-link smoke script exists', () {
    expect(script.existsSync(), isTrue);
    expect(runner.existsSync(), isTrue);
  });

  test('script covers v2d migration and deep-link audit checks', () {
    final sql = script.readAsStringSync();
    expect(sql, contains('settings_user_invitation_v2d'));
    expect(sql, contains('p_target_membership_id'));
    expect(sql, contains('settings_invitation_v2d'));
    expect(sql, contains("action = 'invitation.accepted'"));
    expect(sql, contains('auth_linked'));
  });
}
