import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login_username migration defines helpers and unique index', () {
    final file = File(
      'supabase/migrations/20260811100000_profile_login_username_v1.sql',
    );
    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();

    expect(sql, contains('login_username'));
    expect(sql, contains('profiles_login_username_unique_idx'));
    expect(sql, contains('normalize_login_username'));
    expect(sql, contains('resolve_login_email'));
    expect(sql, contains('set_profile_login_username_v1'));
    expect(sql, contains('login_username_taken'));
  });

  test('backfill migration assigns usernames to existing profiles', () {
    final file = File(
      'supabase/migrations/20260811110000_backfill_profile_login_username_v1.sql',
    );
    expect(file.existsSync(), isTrue);
    final sql = file.readAsStringSync();

    expect(sql, contains('_backfill_suggest_login_username'));
    expect(sql, contains('login_username is null'));
  });
}
