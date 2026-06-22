import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260602130000_ftr_sessions_insert_policy_hardening_v1.sql',
  );

  test('hardening migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('migration creates a single hardened insert policy', () {
    final sql = migration.readAsStringSync();
    expect(
      sql,
      contains('create policy physiotherapy_sessions_insert_doctor_physio_hardened_v1'),
    );
    expect(sql, contains('for insert'));
    expect(sql, contains("'doctor_admin'"));
    expect(sql, contains("'physiotherapist'"));
    expect(sql, isNot(contains("'assistant_secretary'")));
    expect(sql, isNot(contains("'nurse'")));
  });

  test('migration enforces referral patient/tenant consistency', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('from physiotherapy_referrals r'));
    expect(sql, contains('r.patient_id = physiotherapy_sessions.patient_id'));
    expect(sql, contains('r.tenant_id = current_tenant_id()'));
    expect(sql, contains('r.deleted_at is null'));
  });

  test('migration does not depend on patients table subquery', () {
    final sql = migration.readAsStringSync();
    expect(sql, isNot(contains('from patients p')));
  });

  test('migration does not add update/delete policies', () {
    final sql = migration.readAsStringSync();
    expect(sql, isNot(contains('for update')));
    expect(sql, isNot(contains('for delete')));
  });
}
