import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_route_permissions.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/tenant/tenant_financial_feature_gate.dart';
import 'package:v2mem_clinic/core/tenant/tenant_role_access_gate.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_financial_feature_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_role_access_settings.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

/// Automated gate for LIVE-DOC / LIVE-AST / LIVE-PHY manual E2E checklists.
///
/// Does not hit Supabase — validates route/permission matrix that staging
/// live trials depend on. See docs/staging_live_e2e_readiness_execution_v1.md.
void main() {
  tearDown(() {
    AuthSession.clear();
    TenantRoleAccessGate.reset();
    TenantFinancialFeatureGate.reset();
  });

  AppUser user(String role) => AppUser(
        id: 'gate-$role',
        username: role,
        displayName: role,
        role: role,
      );

  void asRole(String role) {
    AuthSession.setUser(user(role));
    TenantRoleAccessGate.apply(TenantRoleAccessSettings.empty());
    TenantFinancialFeatureGate.apply(TenantFinancialFeatureSettings.defaults);
  }

  bool can(String role, String path) {
    asRole(role);
    return AuthRoutePermissions.canAccessPath(path);
  }

  group('LIVE-DOC doctor/admin gate', () {
    test('core clinical and audit paths', () {
      expect(can(AppRoles.doctor, '/clinical-records'), isTrue);
      expect(can(AppRoles.doctor, '/clinical-records/new'), isTrue);
      expect(can(AppRoles.doctor, '/audit-logs'), isTrue);
      expect(can(AppRoles.doctor, '/patient-timeline'), isTrue);
      expect(can(AppRoles.doctor, '/prescriptions'), isTrue);
      expect(can(AppRoles.doctor, '/prescriptions/new'), isTrue);
      expect(can(AppRoles.doctor, '/lab-orders'), isTrue);
      expect(can(AppRoles.doctor, '/radiology-orders'), isTrue);
      expect(can(AppRoles.doctor, '/clinical-reports'), isTrue);
      expect(can(AppRoles.doctor, '/messages'), isTrue);
    });
  });

  group('LIVE-AST assistant gate', () {
    test('operational paths without full clinical', () {
      expect(can(AppRoles.assistant, '/clinical-records'), isFalse);
      expect(can(AppRoles.assistant, '/clinical-records/enc-1'), isFalse);
      expect(
        can(AppRoles.assistant, '/clinical-records/diagnosis-summary'),
        isTrue,
      );
      expect(can(AppRoles.assistant, '/appointments'), isTrue);
      expect(can(AppRoles.assistant, '/patients'), isTrue);
      expect(can(AppRoles.assistant, '/prescriptions'), isTrue);
      expect(can(AppRoles.assistant, '/prescriptions/new'), isFalse);
      expect(can(AppRoles.assistant, '/audit-logs'), isFalse);
      expect(can(AppRoles.assistant, '/patient-timeline'), isFalse);
    });
  });

  group('LIVE-PHY physiotherapist gate', () {
    test('FTR scope without full clinical or audit', () {
      expect(can(AppRoles.physiotherapist, '/clinical-records'), isFalse);
      expect(
        can(AppRoles.physiotherapist, '/clinical-records/diagnosis-summary'),
        isFalse,
      );
      expect(
        can(AppRoles.physiotherapist, '/physiotherapy/clinical-summaries'),
        isTrue,
      );
      expect(
        can(AppRoles.physiotherapist, '/physiotherapy/referrals/pending'),
        isTrue,
      );
      expect(can(AppRoles.physiotherapist, '/appointments/new'), isTrue);
      expect(can(AppRoles.physiotherapist, '/audit-logs'), isFalse);
      expect(can(AppRoles.physiotherapist, '/pdf-outputs'), isFalse);
    });
  });
}
