import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260702100000_operational_records_remote_v2b_inventory.sql',
  );

  test('operational records v2b inventory migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('migration creates inventory_items and inventory_movements', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('create table if not exists inventory_items'));
    expect(sql, contains('create table if not exists inventory_movements'));
  });

  test('migration enables RLS on both tables', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('alter table inventory_items enable row level security'));
    expect(sql, contains('alter table inventory_movements enable row level security'));
  });

  test('migration allows doctor_admin and nurse only', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains("array['doctor_admin', 'nurse']"));
    expect(sql, isNot(contains('assistant_secretary')));
    expect(sql, isNot(contains("'physiotherapist'")));
  });

  test('migration defines record_inventory_movement RPC', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('create or replace function record_inventory_movement'));
    expect(sql, contains('security definer'));
    expect(sql, contains('for update'));
    expect(sql, contains('grant execute on function record_inventory_movement'));
  });

  test('movement direct insert revoked from authenticated', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('revoke insert on inventory_movements from authenticated'));
  });

  test('migration reuses set_updated_at trigger', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('execute function set_updated_at()'));
    expect(sql, isNot(contains('create or replace function set_updated_at')));
  });

  test('movement type check constraint exists', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains("movement_type in ('giris', 'cikis', 'duzeltme')"));
  });
}
