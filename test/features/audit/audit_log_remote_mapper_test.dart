import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/audit/access/audit_access_event_type.dart';
import 'package:v2mem_clinic/features/audit/data/audit_log_remote_mapper.dart';
import 'package:v2mem_clinic/features/audit/models/audit_log.dart';

void main() {
  test('maps remote row to audit log', () {
    final log = AuditLogRemoteMapper.fromRow({
      'id': '11111111-1111-1111-1111-111111111111',
      'tenant_id': '22222222-2222-2222-2222-222222222222',
      'actor_profile_id': '33333333-3333-3333-3333-333333333333',
      'action': AuditAccessEventType.clinicalFullView,
      'module': 'clinical',
      'record_id': null,
      'patient_id': '44444444-4444-4444-4444-444444444444',
      'metadata': {'success': true},
      'created_at': '2026-06-01T10:00:00.000Z',
      'patients': {'full_name': 'Test Hasta'},
      'profiles': {'display_name': 'Dr. Test'},
    });

    expect(log.patientName, 'Test Hasta');
    expect(log.userName, 'Dr. Test');
    expect(log.actionType, ActionType.hastaDosyasiAcma);
    expect(log.module, ModuleType.muayene);
    expect(log.description, contains('muayene'));
  });
}
