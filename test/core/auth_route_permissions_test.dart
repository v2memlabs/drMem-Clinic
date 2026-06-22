import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_route_permissions.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/navigation/app_nav_config.dart';
import 'package:v2mem_clinic/core/tenant/tenant_financial_feature_gate.dart';
import 'package:v2mem_clinic/core/tenant/tenant_role_access_gate.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_financial_feature_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_role_access_settings.dart';
import 'package:v2mem_clinic/features/settings/settings_categories.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    TenantRoleAccessGate.reset();
    TenantFinancialFeatureGate.reset();
  });

  AppUser user(String role) => AppUser(
        id: 'u-$role',
        username: role,
        displayName: role,
        role: role,
      );

  void asRole(String role) {
    AuthSession.setUser(user(role));
    TenantRoleAccessGate.apply(TenantRoleAccessSettings.empty());
    TenantFinancialFeatureGate.apply(TenantFinancialFeatureSettings.defaults);
  }

  group('Full clinical routes', () {
    test('doctor can access clinical list and detail', () {
      asRole(AppRoles.doctor);
      expect(AuthRoutePermissions.canAccessPath('/clinical-records'), isTrue);
      expect(
        AuthRoutePermissions.canAccessPath('/clinical-records/enc-1'),
        isTrue,
      );
      expect(
        AuthRoutePermissions.canAccessPath('/clinical-records/new'),
        isTrue,
      );
    });

    test('assistant cannot access full clinical', () {
      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/clinical-records'), isFalse);
      expect(
        AuthRoutePermissions.canAccessPath('/clinical-records/enc-1'),
        isFalse,
      );
    });

    test('physiotherapist cannot access full clinical', () {
      asRole(AppRoles.physiotherapist);
      expect(AuthRoutePermissions.canAccessPath('/clinical-records'), isFalse);
    });

    test('nurse cannot access full clinical', () {
      asRole(AppRoles.nurse);
      expect(AuthRoutePermissions.canAccessPath('/clinical-records'), isFalse);
    });
  });

  group('Safe summary routes', () {
    test('assistant and doctor can access diagnosis summary', () {
      asRole(AppRoles.assistant);
      expect(
        AuthRoutePermissions.canAccessPath('/clinical-records/diagnosis-summary'),
        isTrue,
      );
      asRole(AppRoles.doctor);
      expect(
        AuthRoutePermissions.canAccessPath('/clinical-records/diagnosis-summary'),
        isTrue,
      );
    });

    test('physio and nurse cannot access diagnosis summary', () {
      asRole(AppRoles.physiotherapist);
      expect(
        AuthRoutePermissions.canAccessPath('/clinical-records/diagnosis-summary'),
        isFalse,
      );
      asRole(AppRoles.nurse);
      expect(
        AuthRoutePermissions.canAccessPath('/clinical-records/diagnosis-summary'),
        isFalse,
      );
    });

    test('physio and doctor can access physio clinical summaries', () {
      asRole(AppRoles.physiotherapist);
      expect(
        AuthRoutePermissions.canAccessPath('/physiotherapy/clinical-summaries'),
        isTrue,
      );
      asRole(AppRoles.doctor);
      expect(
        AuthRoutePermissions.canAccessPath('/physiotherapy/clinical-summaries'),
        isTrue,
      );
    });

    test('assistant and nurse cannot access physio clinical summaries', () {
      asRole(AppRoles.assistant);
      expect(
        AuthRoutePermissions.canAccessPath('/physiotherapy/clinical-summaries'),
        isFalse,
      );
      asRole(AppRoles.nurse);
      expect(
        AuthRoutePermissions.canAccessPath('/physiotherapy/clinical-summaries'),
        isFalse,
      );
    });
  });

  group('Sensitive modules', () {
    test('audit only doctor', () {
      asRole(AppRoles.doctor);
      expect(AuthRoutePermissions.canAccessPath('/audit-logs'), isTrue);
      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/audit-logs'), isFalse);
      asRole(AppRoles.physiotherapist);
      expect(AuthRoutePermissions.canAccessPath('/audit-logs'), isFalse);
      asRole(AppRoles.nurse);
      expect(AuthRoutePermissions.canAccessPath('/audit-logs'), isFalse);
    });

    test('timeline only doctor', () {
      asRole(AppRoles.doctor);
      expect(AuthRoutePermissions.canAccessPath('/patient-timeline'), isTrue);
      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/patient-timeline'), isFalse);
      asRole(AppRoles.nurse);
      expect(AuthRoutePermissions.canAccessPath('/patient-timeline'), isFalse);
    });

    test('pdf outputs doctor and assistant', () {
      asRole(AppRoles.doctor);
      expect(AuthRoutePermissions.canAccessPath('/pdf-outputs'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/pdf-outputs/new'), isTrue);
      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/pdf-outputs'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/pdf-outputs/new'), isTrue);
      asRole(AppRoles.physiotherapist);
      expect(AuthRoutePermissions.canAccessPath('/pdf-outputs'), isFalse);
    });

    test('prescriptions and reports viewable by assistant', () {
      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/prescriptions'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/prescriptions/rx1'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/prescriptions/new'), isFalse);
      expect(AuthRoutePermissions.canAccessPath('/clinical-reports'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/clinical-reports/r1'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/clinical-reports/new'), isFalse);
    });

    test('payments doctor, assistant and physiotherapist', () {
      asRole(AppRoles.doctor);
      expect(AuthRoutePermissions.canAccessPath('/payments'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/payments/new'), isTrue);
      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/payments'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/payments/new'), isTrue);
      asRole(AppRoles.physiotherapist);
      expect(AuthRoutePermissions.canAccessPath('/payments'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/payments/new'), isTrue);
      asRole(AppRoles.nurse);
      expect(AuthRoutePermissions.canAccessPath('/payments'), isFalse);
      expect(AuthRoutePermissions.canAccessPath('/payments/new'), isFalse);
    });

    test('payments denied when payment_records financial flag is off', () {
      asRole(AppRoles.doctor);
      TenantFinancialFeatureGate.apply(
        TenantFinancialFeatureSettings.defaults.copyWithFlag(
          TenantFinancialFeatureKey.paymentRecords,
          false,
        ),
      );

      expect(AuthRoutePermissions.canAccessPath('/payments'), isFalse);
      expect(AuthRoutePermissions.canAccessPath('/payments/new'), isFalse);
    });

    test('payments denied when role access revoked', () {
      asRole(AppRoles.doctor);
      TenantRoleAccessGate.apply(
        TenantRoleAccessSettings.empty().copyWithFlag(
          AppRoles.doctor,
          TenantRoleAccessKey.viewPayments,
          false,
        ),
      );

      expect(AuthSession.canViewPayments, isFalse);
      expect(AuthRoutePermissions.canAccessPath('/payments'), isFalse);
    });

    test('payment create denied when create_payments role access revoked', () {
      asRole(AppRoles.physiotherapist);
      TenantRoleAccessGate.apply(
        TenantRoleAccessSettings.empty().copyWithFlag(
          AppRoles.physiotherapist,
          TenantRoleAccessKey.createPayments,
          false,
        ),
      );

      expect(AuthSession.canCreatePayments, isFalse);
      expect(AuthRoutePermissions.canAccessPath('/payments/new'), isFalse);
    });

    test('inventory doctor and nurse', () {
      asRole(AppRoles.doctor);
      expect(AuthRoutePermissions.canAccessPath('/inventory'), isTrue);
      asRole(AppRoles.nurse);
      expect(AuthRoutePermissions.canAccessPath('/inventory'), isTrue);
      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/inventory'), isFalse);
    });
  });

  group('Settings routes', () {
    test('clinical staff can access shared settings paths', () {
      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/settings/profile'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/settings/display-region'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/settings/system-security'), isTrue);
    });

    test('doctor-only settings paths', () {
      asRole(AppRoles.doctor);
      expect(AuthRoutePermissions.canAccessPath('/settings/clinic'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/settings/patient-settings'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/settings/clinic-finance'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/settings/demo-usage'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/settings/subscription'), isTrue);

      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/settings/clinic'), isFalse);
      expect(AuthRoutePermissions.canAccessPath('/settings/patient-settings'), isFalse);
      expect(AuthRoutePermissions.canAccessPath('/settings/clinic-finance'), isFalse);
      expect(AuthRoutePermissions.canAccessPath('/settings/demo-usage'), isFalse);
      expect(AuthRoutePermissions.canAccessPath('/settings/subscription'), isFalse);

      asRole(AppRoles.nurse);
      expect(AuthRoutePermissions.canAccessPath('/settings/demo-usage'), isFalse);
      expect(AuthRoutePermissions.canAccessPath('/settings/subscription'), isFalse);
    });

    test('users-roles and invite paths are doctor-only', () {
      asRole(AppRoles.doctor);
      expect(AuthRoutePermissions.canAccessPath('/settings/users-roles'), isTrue);

      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/settings/users-roles'), isFalse);
      expect(
        AuthRoutePermissions.canAccessPath('/settings/users-roles/invite'),
        isFalse,
      );
    });

    test('visible settings hub categories are route-accessible for doctor', () {
      asRole(AppRoles.doctor);
      for (final category in SettingsCategories.visibleForCurrentUser()) {
        expect(
          AuthRoutePermissions.canAccessPath(category.routePath),
          isTrue,
          reason: category.routePath,
        );
      }
    });
  });

  group('Clinic workflow routes', () {
    test('clinical staff can access workflow and leave request paths', () {
      asRole(AppRoles.assistant);
      expect(AuthRoutePermissions.canAccessPath('/clinic-workflow'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/settings/clinic-workflow'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/staff-leave-requests'), isTrue);
      expect(AuthRoutePermissions.canAccessPath('/staff-leaves'), isTrue);
      expect(
        AuthRoutePermissions.canAccessPath('/settings/clinic-workflow/staff-leaves'),
        isTrue,
      );
    });
  });

  group('Sidebar menu vs route permissions', () {
    test('visible nav items are route-accessible for doctor', () {
      asRole(AppRoles.doctor);
      for (final section in buildAppNavSections()) {
        for (final item in section.items) {
          if (item.visible()) {
            expect(
              AuthRoutePermissions.canAccessPath(item.route),
              isTrue,
              reason: 'Menu item ${item.route} visible but path denied',
            );
          }
        }
      }
    });

    test('visible nav items are route-accessible for assistant', () {
      asRole(AppRoles.assistant);
      for (final section in buildAppNavSections()) {
        for (final item in section.items) {
          if (item.visible()) {
            expect(
              AuthRoutePermissions.canAccessPath(item.route),
              isTrue,
              reason: 'Menu item ${item.route}',
            );
          }
        }
      }
    });

    test('visible nav items are route-accessible for physiotherapist', () {
      asRole(AppRoles.physiotherapist);
      for (final section in buildAppNavSections()) {
        for (final item in section.items) {
          if (item.visible()) {
            expect(
              AuthRoutePermissions.canAccessPath(item.route),
              isTrue,
              reason: 'Menu item ${item.route}',
            );
          }
        }
      }
    });

    test('assistant menu does not expose full clinical or audit', () {
      asRole(AppRoles.assistant);
      final routes = buildAppNavSections()
          .expand((s) => s.items)
          .where((i) => i.visible())
          .map((i) => i.route)
          .toList();
      expect(routes, isNot(contains('/clinical-records')));
      expect(routes, isNot(contains('/audit-logs')));
      expect(routes, isNot(contains('/patient-timeline')));
      expect(routes, isNot(contains('/patient-tags')));
      expect(routes, isNot(contains('/patient-alerts')));
    });

    test('doctor menu excludes removed legacy sidebar routes', () {
      asRole(AppRoles.doctor);
      final routes = buildAppNavSections()
          .expand((s) => s.items)
          .where((i) => i.visible())
          .map((i) => i.route)
          .toList();
      expect(routes, isNot(contains('/patient-timeline')));
      expect(routes, isNot(contains('/patient-tags')));
      expect(routes, isNot(contains('/patient-alerts')));
      expect(routes, isNot(contains('/anamnesis')));
      expect(routes, contains('/audit-logs'));
      expect(routes, contains('/settings'));
    });

    test('physio and nurse menus exclude audit', () {
      asRole(AppRoles.physiotherapist);
      final physioRoutes = buildAppNavSections()
          .expand((s) => s.items)
          .where((i) => i.visible())
          .map((i) => i.route)
          .toList();
      expect(physioRoutes, isNot(contains('/audit-logs')));
      expect(physioRoutes, contains('/physiotherapy/clinical-summaries'));

      asRole(AppRoles.nurse);
      final nurseRoutes = buildAppNavSections()
          .expand((s) => s.items)
          .where((i) => i.visible())
          .map((i) => i.route)
          .toList();
      expect(nurseRoutes, isNot(contains('/audit-logs')));
      expect(nurseRoutes, isNot(contains('/patient-timeline')));
    });
  });
}
