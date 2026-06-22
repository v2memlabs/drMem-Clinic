import '../../core/auth/tenant_role_mapper.dart';
import '../../core/constants/app_roles.dart';

/// Ayarlar ekranı ürün dili — teknik rol kodları kullanıcıya gösterilmez.
abstract final class SettingsProductLabels {
  static String roleLabel(String? role) {
    if (role == null) return '—';
    final flutterRole = TenantRoleMapper.toFlutterRole(role) ?? role;
    return AppRoles.roleLabel(flutterRole);
  }

  static String membershipStatusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'invited':
        return 'Davetli';
      case 'disabled':
        return 'Pasif';
      default:
        return '—';
    }
  }
}
