import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260826140000_physio_appointment_booking_rls_v1.sql',
  );

  test('physio appointment booking migration exists', () {
    expect(migration.existsSync(), isTrue);
  });

  test('migration adds physio insert and updates access gate', () {
    final sql = migration.readAsStringSync();
    expect(sql, contains('appointments_insert_physio_own_v1'));
    expect(sql, contains('assigned_physiotherapist_profile_id = current_profile_id()'));
    expect(sql, contains("'edit_physiotherapy'"));
    expect(sql, contains("'edit_appointments'"));
  });
}
