import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260704100000_ftr_sessions_remote_v2.sql',
  );

  test('ftr sessions v2 migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('migration creates physiotherapy_sessions table', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('create table if not exists physiotherapy_sessions'));
    expect(sql, contains('referral_id uuid not null references physiotherapy_referrals'));
    expect(sql, contains('patient_id uuid not null references patients'));
    expect(sql, contains('physiotherapist_profile_id uuid not null references profiles'));
  });

  test('migration enables RLS', () {
    final sql = migration.readAsStringSync();
    expect(
      sql,
      contains('alter table physiotherapy_sessions enable row level security'),
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
  });

  test('migration enforces referral and patient tenant scope on insert', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('from physiotherapy_referrals r'));
    expect(sql, contains('r.patient_id = patient_id'));
    expect(sql, contains('from patients p'));
    expect(sql, contains('p.tenant_id = tenant_id'));
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

  test('migration pain_score constraint 0-10', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('physiotherapy_sessions_pain_score_check'));
    expect(sql, contains('pain_score >= 0'));
    expect(sql, contains('pain_score <= 10'));
  });

  test('migration return_to_sport_stage uses existing enum values', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains("'uygun_degil'"));
    expect(sql, contains("'maca_donus'"));
  });

  test('migration has no hard delete policy', () {
    final sql = migration.readAsStringSync();
    expect(sql, isNot(contains('for delete')));
  });

  test('migration has no session update policy in v2', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('session update: no UPDATE policy'));
    expect(sql, isNot(contains('for update')));
  });

  test('migration has no internal_doctor_note or clinical_data columns', () {
    final sql = migration.readAsStringSync();
    expect(sql, isNot(contains('internal_doctor_note')));
    expect(sql, isNot(contains('clinical_data')));
  });
}
