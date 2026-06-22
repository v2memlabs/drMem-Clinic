import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final pack = File(
    'supabase/migrations/20260805110000_p0_stabilization_integrity_pack_v1.sql',
  );
  final bucket = File(
    'supabase/migrations/20260530100000_patient_files_private_storage_bucket_v1.sql',
  );
  final metadata = File(
    'supabase/migrations/20260525200000_patient_file_pdf_storage_metadata_v1.sql',
  );

  test('legacy bucket policy was tenant-prefix only (confirmed gap)', () {
    final sql = bucket.readAsStringSync();
    expect(sql, contains('patient_files_storage_select_v1'));
    expect(sql, contains('has_tenant_role'));
    expect(sql, isNot(contains('_storage_object_metadata_visible')));
  });

  test('table metadata RLS uses visibility_scope role matrix', () {
    final sql = metadata.readAsStringSync();
    expect(sql, contains('patient_files_select_metadata_v1'));
    expect(sql, contains("visibility_scope = 'clinic_operations'"));
    expect(sql, contains("visibility_scope = 'physiotherapy'"));
    expect(sql, contains('pdf_outputs_select_doctor_draft_v1'));
  });

  test('P0 pack closes metadata deny vs object allow gap', () {
    final sql = pack.readAsStringSync();
    expect(sql, contains('_storage_object_metadata_visible(name)'));
    final selectPolicy = sql
        .split('create policy patient_files_storage_select_v1')[1]
        .split('-- INSERT unchanged')[0];
    expect(selectPolicy, isNot(contains('assistant_secretary')));
  });
}
