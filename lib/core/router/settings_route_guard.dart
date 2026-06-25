import '../auth/auth_route_permissions.dart';
import '../auth/auth_session.dart';
import '../../features/settings/clinic_finance_statistics_screen.dart';

/// Ayarlar rotaları için tek kaynak erişim kontrolü.
///
/// [AuthRoutePermissions] ile aynı semantik; finans istatistikleri için ek
/// tenant finans gate uygulanır. Router builder'ları bu sınıfı kullanmalı.
abstract final class SettingsRouteGuard {
  static String? denyMessageForPath(String location) {
    final path = Uri.parse(location).path;

    if (path == '/settings/clinic-finance') {
      if (!AuthSession.canViewDoctorOnlySettings) {
        return _doctorOnlySettingsDeny;
      }
      if (!clinicFinanceStatisticsVisible()) {
        return 'Finansal istatistiklere yalnızca klinik yönetimi erişebilir.';
      }
      return null;
    }

    if (AuthRoutePermissions.canAccessPath(path)) {
      return null;
    }

    return _denyMessageForDeniedPath(path);
  }

  static const _doctorOnlySettingsDeny =
      'Bu ayar sayfasına bu rol ile erişilemez.';

  static String _denyMessageForDeniedPath(String path) {
    if (!AuthSession.isLoggedIn) {
      return 'Ayarlar için giriş yapmanız gerekir.';
    }

    if (path == '/settings/users-roles/invite') {
      return 'Kullanıcı daveti yalnızca doktor hesabı tarafından gönderilebilir.';
    }
    if (path == '/settings/users-roles' || path.startsWith('/settings/users-roles/')) {
      return 'Kullanıcılar ve roller yalnızca doktor hesabı tarafından yönetilebilir.';
    }

    if (_isDoctorOnlySettingsPath(path)) {
      return _doctorOnlySettingsDeny;
    }

    if (path == '/clinic-workflow' || path == '/settings/clinic-workflow') {
      return 'Klinik işleyiş ayarlarına erişim yetkiniz yok.';
    }

    if (path == '/staff-leaves' ||
        path == '/settings/clinic-workflow/staff-leaves') {
      return 'Personel izinlerine erişim yetkiniz yok.';
    }

    if (path == '/staff-leave-requests') {
      return 'İzin talebine erişim yetkiniz yok.';
    }

    if (path == '/settings' || path.startsWith('/settings/')) {
      return 'Ayarlar için giriş yapmanız gerekir.';
    }

    return _doctorOnlySettingsDeny;
  }

  static bool _isDoctorOnlySettingsPath(String path) {
    return path == '/settings/clinic' ||
        path == '/settings/patient-settings' ||
        path == '/settings/demo-usage' ||
        path == '/settings/subscription';
  }
}
