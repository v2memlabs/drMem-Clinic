import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_route_permissions.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/router/settings_route_guard.dart';
import 'package:v2mem_clinic/core/tenant/tenant_financial_feature_gate.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_financial_feature_settings.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    TenantFinancialFeatureGate.reset();
  });

  AppUser user(String role) => AppUser(
        id: 'u-$role',
        username: role,
        displayName: 'Test',
        role: role,
      );

  group('SettingsRouteGuard', () {
    test('allows doctor on all standard settings paths', () {
      AuthSession.setUser(user(AppRoles.doctor));
      TenantFinancialFeatureGate.apply(TenantFinancialFeatureSettings.defaults);
      for (final path in [
        '/settings',
        '/settings/profile',
        '/settings/clinic',
        '/settings/patient-settings',
        '/settings/clinic-finance',
        '/settings/demo-usage',
        '/settings/subscription',
        '/settings/users-roles',
        '/settings/clinic-workflow',
      ]) {
        expect(
          SettingsRouteGuard.denyMessageForPath(path),
          isNull,
          reason: path,
        );
        expect(AuthRoutePermissions.canAccessPath(path), isTrue, reason: path);
      }
    });

    test('denies assistant on doctor-only settings paths', () {
      AuthSession.setUser(user(AppRoles.assistant));
      for (final path in [
        '/settings/clinic',
        '/settings/patient-settings',
        '/settings/demo-usage',
        '/settings/subscription',
      ]) {
        expect(
          SettingsRouteGuard.denyMessageForPath(path),
          'Bu ayar sayfasına bu rol ile erişilemez.',
          reason: path,
        );
        expect(AuthRoutePermissions.canAccessPath(path), isFalse, reason: path);
      }
    });

    test('allows assistant on staff settings paths', () {
      AuthSession.setUser(user(AppRoles.assistant));
      for (final path in [
        '/settings',
        '/settings/profile',
        '/settings/display-region',
        '/settings/system-security',
        '/settings/clinic-workflow',
      ]) {
        expect(
          SettingsRouteGuard.denyMessageForPath(path),
          isNull,
          reason: path,
        );
      }
    });

    test('denies assistant on users-roles paths', () {
      AuthSession.setUser(user(AppRoles.assistant));
      expect(
        SettingsRouteGuard.denyMessageForPath('/settings/users-roles'),
        'Kullanıcılar ve roller yalnızca doktor hesabı tarafından yönetilebilir.',
      );
      expect(
        SettingsRouteGuard.denyMessageForPath('/settings/users-roles/invite'),
        'Kullanıcı daveti yalnızca doktor hesabı tarafından gönderilebilir.',
      );
    });

    test('denies doctor on clinic-finance when payment records disabled', () {
      AuthSession.setUser(user(AppRoles.doctor));
      TenantFinancialFeatureGate.apply(
        TenantFinancialFeatureSettings.defaults.copyWithFlag(
          TenantFinancialFeatureKey.paymentRecords,
          false,
        ),
      );
      expect(
        SettingsRouteGuard.denyMessageForPath('/settings/clinic-finance'),
        'Finansal istatistiklere yalnızca klinik yönetimi erişebilir.',
      );
      expect(
        AuthRoutePermissions.canAccessPath('/settings/clinic-finance'),
        isFalse,
      );
    });

    test('denies logged-out user on settings hub', () {
      expect(
        SettingsRouteGuard.denyMessageForPath('/settings'),
        'Ayarlar için giriş yapmanız gerekir.',
      );
    });
  });
}
