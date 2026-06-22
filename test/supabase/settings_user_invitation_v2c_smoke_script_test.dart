import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final script = File('scripts/staging/settings_user_invitation_v2c_smoke_checks.sql');

  test('v2c staging smoke script exists', () {
    expect(script.existsSync(), isTrue);
  });

  test('script covers invitation RPCs grants and audit checks', () {
    final sql = script.readAsStringSync();
    expect(sql, contains('bootstrap_tenant_invited_user_v2'));
    expect(sql, contains('cancel_tenant_invitation_v2'));
    expect(sql, contains('prepare_tenant_invitation_resend_v2'));
    expect(sql, contains('last_invited_at'));
    expect(sql, contains('user.invite.resend'));
    expect(sql, contains('user.invite.cancel'));
    expect(sql, contains('doctor-a@example.test'));
    expect(sql, contains('maintenance_config'));
  });
}
