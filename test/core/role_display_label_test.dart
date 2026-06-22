import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/tenant_role_mapper.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/settings/settings_product_labels.dart';

void main() {
  group('AppRoles.roleLabel', () {
    test('flutter roles show simplified Turkish labels', () {
      expect(AppRoles.roleLabel(AppRoles.doctor), 'Doktor');
      expect(AppRoles.roleLabel(AppRoles.assistant), 'Asistan');
      expect(AppRoles.roleLabel(AppRoles.physiotherapist), 'Fizyoterapist');
      expect(AppRoles.roleLabel(AppRoles.nurse), 'Hemşire');
    });

    test('forbidden composite labels are not used', () {
      for (final role in AppRoles.all) {
        final label = AppRoles.roleLabel(role);
        expect(label, isNot(contains('Admin')));
        expect(label, isNot(contains('Sekreter')));
        expect(label, isNot(contains('/')));
      }
    });
  });

  group('SettingsProductLabels.roleLabel', () {
    test('maps DB role values to user-facing labels', () {
      expect(
        SettingsProductLabels.roleLabel(TenantRoleMapper.dbDoctorAdmin),
        'Doktor',
      );
      expect(
        SettingsProductLabels.roleLabel(TenantRoleMapper.dbAssistantSecretary),
        'Asistan',
      );
      expect(
        SettingsProductLabels.roleLabel(TenantRoleMapper.dbPhysiotherapist),
        'Fizyoterapist',
      );
      expect(
        SettingsProductLabels.roleLabel(TenantRoleMapper.dbNurse),
        'Hemşire',
      );
    });

    test('null role shows em dash', () {
      expect(SettingsProductLabels.roleLabel(null), '—');
    });
  });
}
