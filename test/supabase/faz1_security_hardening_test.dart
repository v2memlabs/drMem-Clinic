import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260822100000_faz1_security_hardening_v1.sql',
  );
  final credentialsEmail = File(
    'supabase/functions/send-account-credentials-email/index.ts',
  );
  final signInUsername = File(
    'supabase/functions/sign-in-with-username/index.ts',
  );
  final config = File('supabase/config.toml');
  final authRepo = File('lib/core/auth/supabase_auth_repository.dart');

  test('faz1 security migration exists with hardening primitives', () {
    expect(migration.existsSync(), isTrue);
    final sql = migration.readAsStringSync();

    expect(sql, contains('profiles_guard_privileged_columns'));
    expect(sql, contains('maintenance_forbidden'));
    expect(sql, isNot(contains("'error', sqlerrm")));
    expect(sql, contains('revoke all on function public.resolve_login_email'));
    expect(sql, contains('grant execute on function public.resolve_login_email(text) to service_role'));
    expect(sql, contains('current_is_maintenance_operator'));
    expect(sql, contains('as restrictive'));
    expect(sql, contains('patient_files_storage_deny_maintenance_operator_v1'));
  });

  test('send-account-credentials-email requires service role bearer', () {
    expect(credentialsEmail.existsSync(), isTrue);
    final src = credentialsEmail.readAsStringSync();

    expect(src, contains('assertServiceRole'));
    expect(src, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(src, contains('"unauthorized"'));
  });

  test('sign-in-with-username resolves email server-side only', () {
    expect(signInUsername.existsSync(), isTrue);
    final src = signInUsername.readAsStringSync();

    expect(src, contains('resolve_login_email'));
    expect(src, contains('signInWithPassword'));
    expect(src, contains('invalid_credentials'));
    expect(src, isNot(contains('return jsonResponse({ ok: true, email')));
  });

  test('config registers sign-in-with-username with verify_jwt', () {
    final toml = config.readAsStringSync();
    expect(toml, contains('[functions.sign-in-with-username]'));
    expect(toml, contains('verify_jwt = true'));
  });

  test('client auth uses sign-in-with-username edge function', () {
    expect(authRepo.existsSync(), isTrue);
    final src = authRepo.readAsStringSync();

    expect(src, contains("'sign-in-with-username'"));
    expect(src, contains('setSession'));
    expect(src, isNot(contains("'resolve_login_email'")));
    expect(src, isNot(contains('signInWithPassword')));
  });

  test('maintenance provision response excludes temporary_password', () {
    final src = File(
      'supabase/functions/maintenance-provision-user-v2/index.ts',
    ).readAsStringSync();
    expect(src, isNot(contains('temporary_password:')));
  });

  test('resolve_login_email allows maintenance operators without membership', () {
    final sql = File(
      'supabase/migrations/20260823100000_resolve_login_email_maintenance_operator_v1.sql',
    ).readAsStringSync();
    expect(sql, contains('maintenance_operator'));
    expect(sql, contains('coalesce(p.maintenance_operator, false) = true'));
  });
}
