import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/maintenance/data/maintenance_provision_errors.dart';
import 'package:v2mem_clinic/features/maintenance/data/maintenance_provision_models.dart';

void main() {
  test('tenant create result parse', () {
    final r = MaintenanceTenantCreateResult.fromJson({
      'ok': true,
      'tenant_id': 't1',
      'name': 'Klinik B',
      'status': 'active',
    });
    expect(r.ok, isTrue);
    expect(r.tenantId, 't1');
    expect(r.name, 'Klinik B');
  });

  test('user provision result parse without temp password in response', () {
    final r = MaintenanceUserProvisionResult.fromJson({
      'ok': true,
      'operation_result': 'created',
      'auth_user_id': 'a1',
      'profile_id': 'p1',
      'membership_id': 'm1',
      'login_username': 'drtest',
    });
    expect(r.ok, isTrue);
    expect(r.loginUsername, 'drtest');
    expect(r.isAlreadyExists, isFalse);
  });

  test('bootstrap status parse chain_ok', () {
    final s = MaintenanceBootstrapStatus.fromJson({
      'ok': true,
      'tenant_id': 't1',
      'profile_id': 'p1',
      'auth_user_id': 'a1',
      'auth_exists': true,
      'profile_exists': true,
      'auth_linked': true,
      'membership_exists': true,
      'membership_active': true,
      'role': 'doctor_admin',
      'tenant_active': true,
      'chain_ok': true,
      'gap_code': null,
    });
    expect(s.chainOk, isTrue);
    expect(s.role, 'doctor_admin');
  });

  test('function error mapping Turkish messages', () {
    expect(
      MaintenanceProvisionErrorMapper.userMessage(
        MaintenanceProvisionFailure.authUserExists,
      ),
      contains('v2c'),
    );
    expect(
      MaintenanceProvisionErrorMapper.fromFunctionError('rollback_failed'),
      MaintenanceProvisionFailure.rollbackFailed,
    );
    expect(
      MaintenanceProvisionErrorMapper.fromPostgrestMessage(
        'maintenance_disabled',
      ),
      MaintenanceProvisionFailure.disabled,
    );
  });

  test('lib maintenance data layer has no service_role key assignment', () {
    final repo = File('lib/features/maintenance/data/maintenance_repository.dart')
        .readAsStringSync();
    expect(repo.contains('service_role'), isFalse);
    expect(repo.contains('SERVICE_ROLE'), isFalse);
  });
}
