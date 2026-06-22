import '../../../core/auth/tenant_role_mapper.dart';
import '../../../core/constants/app_roles.dart';
import '../../settings/settings_product_labels.dart';

/// DB rol → Türkçe etiket (tek kaynak).
abstract final class MaintenanceRoleLabels {
  static const List<String> dbRoles = [
    TenantRoleMapper.dbDoctorAdmin,
    TenantRoleMapper.dbAssistantSecretary,
    TenantRoleMapper.dbPhysiotherapist,
    TenantRoleMapper.dbNurse,
  ];

  static String labelForDbRole(String dbRole) {
    return SettingsProductLabels.roleLabel(dbRole);
  }

  static String? flutterRoleForDb(String dbRole) {
    return TenantRoleMapper.toFlutterRole(dbRole);
  }

  static String labelForFlutterRole(String flutterRole) {
    return AppRoles.roleLabel(flutterRole);
  }
}
