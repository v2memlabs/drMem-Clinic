import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maintenance-provision-user-v2 edge function contract', () {
    final index = File(
      'supabase/functions/maintenance-provision-user-v2/index.ts',
    );
    final mapper = File(
      'supabase/functions/maintenance-provision-user-v2/error_mapper.ts',
    );
    expect(index.existsSync(), isTrue);
    final src = index.readAsStringSync();
    final mapperSrc = mapper.readAsStringSync();

    expect(src, contains('maintenance_ping'));
    expect(src, contains('.createUser'));
    expect(src, contains('maintenance_bootstrap_user_v2'));
    expect(src, contains('deleteUser'));
    expect(src, contains('generateTemporaryPassword'));
    expect(src, contains('redactForLog'));
    expect(mapperSrc, contains('MAINTENANCE_PROVISIONING_ENABLED'));
    expect(src, isNot(contains('temporary_password:')));
    expect(src, isNot(contains('console.log(temporaryPassword')));
    expect(src, isNot(contains('console.log(password')));
  });

  test('edge function error mapper covers bootstrap failures', () {
    final mapper = File(
      'supabase/functions/maintenance-provision-user-v2/error_mapper.ts',
    ).readAsStringSync();

    expect(mapper, contains('database_bootstrap_failed'));
    expect(mapper, contains('rollback_failed'));
    expect(mapper, contains('auth_user_exists'));
  });
}
