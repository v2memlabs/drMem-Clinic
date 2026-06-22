import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260703100000_ftr_referral_remote_v1.sql',
  );

  test('ftr referral v1 migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('migration creates physiotherapy_referrals table', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('create table if not exists physiotherapy_referrals'));
    expect(sql, contains('clinical_encounter_id uuid references clinical_encounters'));
    expect(sql, contains('appointment_id uuid references appointments'));
  });

  test('migration enables RLS', () {
    final sql = migration.readAsStringSync();
    expect(
      sql,
      contains('alter table physiotherapy_referrals enable row level security'),
    );
  });

  test('migration allows doctor_admin and physiotherapist', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains("'doctor_admin'"));
    expect(sql, contains("'physiotherapist'"));
    expect(sql, isNot(contains("'assistant_secretary'")));
    expect(sql, isNot(contains("'nurse'")));
  });

  test('migration comment documents assistant and nurse deny', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('assistant_secretary and nurse: no policies'));
    expect(sql, isNot(contains("array['assistant_secretary']")));
    expect(sql, isNot(contains("array['nurse']")));
  });

  test('migration enforces cross-tenant patient scope on insert', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('from patients p'));
    expect(sql, contains('p.tenant_id = tenant_id'));
    expect(sql, contains('clinical_encounters ce'));
    expect(sql, contains('appointments a'));
  });

  test('migration uses soft delete filter on select', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('deleted_at is null'));
  });

  test('migration reuses set_updated_at trigger function', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('execute function set_updated_at()'));
    expect(sql, isNot(contains('create or replace function set_updated_at')));
  });

  test('migration status check uses existing enum values', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains("'yeni'"));
    expect(sql, contains("'devam'"));
    expect(sql, contains("'tamamlandi'"));
    expect(sql, contains("'doktor_degerlendirmesi_bekliyor'"));
    expect(sql, contains("'iptal'"));
    expect(sql, isNot(contains("'planlandi'")));
  });

  test('migration has no hard delete policy', () {
    final sql = migration.readAsStringSync();
    expect(sql, isNot(contains('for delete')));
  });

  test('migration has no internal_doctor_note or clinical_data columns', () {
    final sql = migration.readAsStringSync();
    expect(sql, isNot(contains('internal_doctor_note')));
    expect(sql, isNot(contains('clinical_data')));
  });
}
