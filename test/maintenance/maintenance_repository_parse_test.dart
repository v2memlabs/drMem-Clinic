import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/maintenance/data/maintenance_models.dart';
import 'package:v2mem_clinic/features/maintenance/data/maintenance_provision_models.dart';

void main() {
  test('maintenance_ping parse', () {
    final r = MaintenancePingResult.fromJson({
      'ok': true,
      'operator_profile_id': 'p1',
    });
    expect(r.ok, isTrue);
    expect(r.operatorProfileId, 'p1');
  });

  test('bootstrap chain parse', () {
    final chain = MaintenanceBootstrapChain.fromJson({
      'auth_user_id': 'a1',
      'auth_user_exists': true,
      'profile': {
        'id': 'p1',
        'auth_user_id': 'a1',
        'has_auth_link': true,
        'maintenance_operator': true,
      },
      'memberships': [
        {
          'membership_id': 'm1',
          'tenant_id': 't1',
          'tenant_name': 'Klinik',
          'tenant_status': 'active',
          'role': 'doctor_admin',
          'membership_status': 'active',
        },
      ],
      'resolved_active_tenant_id': 't1',
      'chain_ok': true,
    });
    expect(chain.chainOk, isTrue);
    expect(chain.memberships.single.role, 'doctor_admin');
  });

  test('bootstrap status v2 parse', () {
    final status = MaintenanceBootstrapStatus.fromJson({
      'ok': true,
      'tenant_id': 't1',
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
    expect(status.chainOk, isTrue);
    expect(status.gapCode, isNull);
  });
}
