import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final index = File('supabase/functions/tenant-invite-user-v2/index.ts');
  final config = File('supabase/config.toml');

  test('tenant-invite-user-v2 function exists', () {
    expect(index.existsSync(), isTrue);
    expect(File('supabase/functions/tenant-invite-user-v2/types.ts').existsSync(), isTrue);
    expect(File('supabase/functions/tenant-invite-user-v2/error_mapper.ts').existsSync(), isTrue);
  });

  test('function uses dual client and inviteUserByEmail', () {
    final source = index.readAsStringSync();
    expect(source, contains('inviteUserByEmail'));
    expect(source, contains('bootstrap_tenant_invited_user_v2'));
    expect(source, contains('Authorization: authHeader'));
    expect(source, isNot(contains('temporaryPassword')));
    expect(source, isNot(contains('maintenance_bootstrap_user_v2')));
    expect(source, isNot(contains('MAINTENANCE_PROVISIONING_ENABLED')));
  });

  test('config registers tenant-invite-user-v2 with verify_jwt', () {
    final toml = config.readAsStringSync();
    expect(toml, contains('[functions.tenant-invite-user-v2]'));
    expect(toml, contains('verify_jwt = true'));
  });

  test('function supports provision, invite and resend modes', () {
    final source = index.readAsStringSync();
    expect(source, contains('mode === "provision"'));
    expect(source, contains('handleProvisionMode'));
    expect(source, contains('bootstrap_tenant_provisioned_user_v2'));
    expect(source, contains('must_change_password'));
    expect(source, contains("mode === \"resend\""));
    expect(source, contains('prepare_tenant_invitation_resend_v2'));
    expect(source, contains('complete_tenant_invitation_resend_v2'));
    expect(source, contains('handleResendMode'));
    expect(source, contains('validateResendRequest'));
  });

  test('resend mode preserves existing auth user and redacts logs', () {
    final source = index.readAsStringSync();
    expect(source, contains('existingUserId'));
    expect(source, contains('generateLink'));
    expect(source, isNot(contains('deleteUser(ctx.auth_user_id)')));
    expect(source, contains('[REDACTED]'));
  });

  test('invite and resend use deep-link accept redirect builder', () {
    final source = index.readAsStringSync();
    expect(source, contains('buildInviteAcceptRedirect'));
    expect(source, contains('/invite/accept'));
    expect(source, contains('membership_id'));
  });

  test('client response excludes email token and invite URL', () {
    final source = index.readAsStringSync();
    expect(source, isNot(contains('invite_url')));
    expect(source, isNot(contains('access_token')));
    expect(source, isNot(contains('refresh_token')));
  });
}
