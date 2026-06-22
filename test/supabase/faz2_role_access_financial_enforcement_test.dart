import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final helpers = File(
    'supabase/migrations/20260824100000_faz2_role_access_financial_helpers_v1.sql',
  );
  final enforcement = File(
    'supabase/migrations/20260824110000_faz2_payment_financial_role_access_rls_v1.sql',
  );

  test('faz2 helper migration defines access and financial helpers', () {
    expect(helpers.existsSync(), isTrue);
    final sql = helpers.readAsStringSync();

    expect(sql, contains('has_role_access'));
    expect(sql, contains('is_financial_feature_enabled'));
    expect(sql, contains('payments_access_allowed'));
    expect(sql, contains('role_access_default_allowed'));
    expect(sql, contains('tenants_guard_privileged_settings_json_v1'));
    expect(sql, contains("'view_payments'"));
    expect(sql, contains("'charge_patient_materials'"));
  });

  test('faz2 payment enforcement migration wires helpers into RLS and RPC', () {
    expect(enforcement.existsSync(), isTrue);
    final sql = enforcement.readAsStringSync();

    expect(sql, contains('payments_access_allowed'));
    expect(sql, contains('assistant_finance_notifications'));
    expect(sql, contains('list_patient_encounters_for_material_charge'));
    expect(sql, contains("'material_charges'"));
    expect(sql, contains("'charge_patient_materials'"));
  });
}
