import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final clinical = File(
    'supabase/migrations/20260824120000_faz2_clinical_role_access_rls_v1.sql',
  );

  test('faz2 clinical enforcement wires has_role_access into core RLS', () {
    expect(clinical.existsSync(), isTrue);
    final sql = clinical.readAsStringSync();

    expect(sql, contains('patients_select_member_draft_v1'));
    expect(sql, contains("'view_patients'"));
    expect(sql, contains("'edit_patients'"));
    expect(sql, contains('patients_select_physio_referred_v1'));

    expect(sql, contains('appointments_select_doctor_own_v1'));
    expect(sql, contains("'view_own_scoped_appointments'"));
    expect(sql, contains("'view_all_appointments'"));
    expect(sql, contains("'edit_appointments'"));

    expect(sql, contains('clinical_encounters_select_doctor_draft_v1'));
    expect(sql, contains("'view_clinical_encounters'"));
    expect(sql, contains("'edit_clinical_encounters'"));

    expect(sql, contains('patient_files_select_metadata_v1'));
    expect(sql, contains("'view_files'"));
    expect(sql, contains("'edit_files'"));
  });

  test('faz2 clinical enforcement updates summary RPC gate and storage', () {
    final sql = clinical.readAsStringSync();

    expect(sql, contains('_clinical_summary_access_allowed'));
    expect(sql, contains("'view_clinical_diagnosis_summary'"));
    expect(sql, contains("'view_clinical_summary'"));
    expect(sql, contains('_storage_object_metadata_visible'));
    expect(sql, contains("'view_pdf_outputs'"));
    expect(sql, contains('patient_files_storage_insert_v1'));
  });
}
