import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_route_permissions.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/tenant/tenant_financial_feature_gate.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_financial_feature_settings.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_role_access_settings.dart';
import 'package:v2mem_clinic/core/tenant/tenant_role_access_gate.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    TenantRoleAccessGate.reset();
    TenantFinancialFeatureGate.reset();
  });

  test('clinic-finance path requires payment records financial flag', () {
    _signInDoctor();

    TenantFinancialFeatureGate.apply(
      TenantFinancialFeatureSettings.defaults.copyWithFlag(
        TenantFinancialFeatureKey.paymentRecords,
        false,
      ),
    );

    expect(
      AuthRoutePermissions.canAccessPath('/settings/clinic-finance'),
      isFalse,
    );

    TenantFinancialFeatureGate.apply(TenantFinancialFeatureSettings.defaults);

    expect(
      AuthRoutePermissions.canAccessPath('/settings/clinic-finance'),
      isTrue,
    );
  });

  test('wizard-payment path requires encounter payment step financial flag', () {
    _signInDoctor();

    TenantFinancialFeatureGate.apply(
      TenantFinancialFeatureSettings.defaults.copyWithFlag(
        TenantFinancialFeatureKey.encounterPaymentStep,
        false,
      ),
    );

    expect(
      AuthRoutePermissions.canAccessPath(
        '/clinical-records/enc-1/wizard-payment?step=1&total=2',
      ),
      isFalse,
    );

    TenantFinancialFeatureGate.apply(TenantFinancialFeatureSettings.defaults);

    expect(
      AuthRoutePermissions.canAccessPath(
        '/clinical-records/enc-1/wizard-payment?step=1&total=2',
      ),
      isTrue,
    );
  });

  test('wizard-payment path denied when payment edit role access revoked', () {
    _signInDoctor();

    final denied = TenantRoleAccessSettings.empty().copyWithFlag(
      AppRoles.doctor,
      TenantRoleAccessKey.editPayments,
      false,
    );
    TenantRoleAccessGate.apply(denied);

    expect(
      AuthRoutePermissions.canAccessPath('/clinical-records/enc-1/wizard-payment'),
      isFalse,
    );
  });
}

void _signInDoctor() {
  AuthSession.setUser(
    AppUser(
      id: 'profile-doctor',
      username: 'doctor',
      displayName: 'Doctor',
      role: AppRoles.doctor,
    ),
  );
  TenantRoleAccessGate.apply(TenantRoleAccessSettings.empty());
  TenantFinancialFeatureGate.apply(TenantFinancialFeatureSettings.defaults);
}
