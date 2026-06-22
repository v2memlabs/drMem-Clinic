import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final pack = File(
    'supabase/migrations/20260805110000_p0_stabilization_integrity_pack_v1.sql',
  );
  final helpersCompat = File(
    'supabase/migrations/20260607095900_user_mgmt_helpers_forward_compat_v1.sql',
  );
  final ftrStub = File(
    'supabase/migrations/20260602125000_ftr_forward_compat_stub_v1.sql',
  );

  test('forward compat migrations exist before dependents', () {
    expect(ftrStub.existsSync(), isTrue);
    expect(helpersCompat.existsSync(), isTrue);
    expect(pack.existsSync(), isTrue);

    expect(
      ftrStub.uri.pathSegments.last,
      '20260602125000_ftr_forward_compat_stub_v1.sql',
    );
    expect(
      helpersCompat.uri.pathSegments.last.compareTo(
        '20260607100000_settings_user_invitation_v2a.sql',
      ),
      lessThan(0),
    );
  });

  group('invitation guard', () {
    test('blocks invited to active via status RPC', () {
      final sql = pack.readAsStringSync();
      expect(sql, contains('invitation_acceptance_required'));
      expect(
        sql,
        contains("v_before_status = 'invited' and p_status = 'active'"),
      );
    });

    test('blocks disabled to invited via status RPC', () {
      final sql = pack.readAsStringSync();
      expect(sql, contains('invitation_flow_required'));
      expect(
        sql,
        contains("v_before_status = 'disabled' and p_status = 'invited'"),
      );
    });
  });

  group('audit actor', () {
    test('resolves actor via auth_user_id scoped to tenant membership', () {
      final sql = pack.readAsStringSync();
      expect(sql, contains('p.auth_user_id = auth.uid()'));
      expect(sql, isNot(contains('p.user_id = auth.uid()')));
      expect(sql, contains('m.tenant_id = v_tenant_id'));
    });

    test('does not add PII keys to metadata sanitizer', () {
      final sql = pack.readAsStringSync();
      expect(sql, isNot(contains("'email'")));
      expect(sql, isNot(contains("'password'")));
      expect(sql, isNot(contains("'token'")));
    });
  });

  group('storage visibility', () {
    test('SELECT policy requires metadata visibility helper', () {
      final sql = pack.readAsStringSync();
      expect(sql, contains('_storage_object_metadata_visible'));
      expect(sql, contains('patient_files pf'));
      expect(sql, contains('pdf_outputs po'));
      expect(sql, contains('visibility_scope'));
    });

    test('metadata helper mirrors patient_files role matrix', () {
      final sql = pack.readAsStringSync();
      expect(sql, contains("'doctor_admin'"));
      expect(sql, contains("'assistant_secretary'"));
      expect(sql, contains("'physiotherapy'"));
      expect(sql, contains("'clinic_operations'"));
    });
  });

  group('FTR session INSERT consolidation', () {
    test('drops legacy split insert policies', () {
      final sql = pack.readAsStringSync();
      expect(
        sql,
        contains(
          'drop policy if exists physiotherapy_sessions_insert_doctor_v1',
        ),
      );
      expect(
        sql,
        contains(
          'drop policy if exists physiotherapy_sessions_insert_physio_v1',
        ),
      );
    });

    test('single hardened policy without patients subquery', () {
      final sql = pack.readAsStringSync();
      expect(
        sql,
        contains(
          'create policy physiotherapy_sessions_insert_doctor_physio_hardened_v1',
        ),
      );
      expect(sql, contains('physiotherapy_referrals r'));
      expect(sql, isNot(contains('from patients p')));
      expect(sql, contains('physiotherapist_profile_id = current_profile_id()'));
    });
  });
}
