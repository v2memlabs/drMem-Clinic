import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260609100000_settings_user_invitation_v2d.sql',
  );
  final edgeFn = File('supabase/functions/tenant-invite-user-v2/index.ts');

  test('v2d migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('bootstrap accepts optional target membership id', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('p_target_membership_id uuid default null'));
    expect(sql, contains('coalesce(p_target_membership_id, gen_random_uuid())'));
  });

  test('accept uses v2d audit source when membership id provided', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('settings_invitation_v2d'));
    expect(sql, contains("when p_membership_id is not null then 'settings_invitation_v2d'"));
  });

  test('edge function builds invite accept redirect with membership id', () {
    final source = edgeFn.readAsStringSync();
    expect(source, contains('buildInviteAcceptRedirect'));
    expect(source, contains('p_target_membership_id'));
    expect(source, contains('crypto.randomUUID()'));
    expect(source, contains('MEMBERSHIP_ID_PARAM'));
  });
}
