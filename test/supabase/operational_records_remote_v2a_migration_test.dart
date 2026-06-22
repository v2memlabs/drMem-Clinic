import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260701100000_operational_records_remote_v2a.sql',
  );

  test('operational records v2a migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('migration creates payments and consents tables', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('create table if not exists payments'));
    expect(sql, contains('create table if not exists consents'));
    expect(sql, contains('patient_file_id uuid references patient_files'));
  });

  test('migration enables RLS on both tables', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('alter table payments enable row level security'));
    expect(sql, contains('alter table consents enable row level security'));
  });

  test('migration allows doctor_admin and assistant_secretary only', () {
    final sql = migration.readAsStringSync();
    expect(
      sql,
      contains(
        "array['doctor_admin', 'assistant_secretary']",
      ),
    );
    expect(sql, isNot(contains("'nurse'")));
    expect(sql, isNot(contains("'physiotherapist'")));
  });

  test('migration enforces cross-tenant patient scope on insert', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('from patients p'));
    expect(sql, contains('p.tenant_id = tenant_id'));
    expect(sql, contains('p.deleted_at is null'));
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

  test('migration has amount constraints on payments', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('payments_total_amount_nonneg'));
    expect(sql, contains('payments_paid_lte_total'));
  });
}
