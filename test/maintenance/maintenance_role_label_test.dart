import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/tenant_role_mapper.dart';
import 'package:v2mem_clinic/features/maintenance/widgets/maintenance_role_labels.dart';

void main() {
  test('DB roller Türkçe etiketlere map edilir', () {
    expect(
      MaintenanceRoleLabels.labelForDbRole(TenantRoleMapper.dbDoctorAdmin),
      'Doktor',
    );
    expect(
      MaintenanceRoleLabels.labelForDbRole(TenantRoleMapper.dbAssistantSecretary),
      'Asistan',
    );
    expect(
      MaintenanceRoleLabels.labelForDbRole(TenantRoleMapper.dbPhysiotherapist),
      'Fizyoterapist',
    );
    expect(
      MaintenanceRoleLabels.labelForDbRole(TenantRoleMapper.dbNurse),
      'Hemşire',
    );
  });
}
