import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/core/tenant/tenant_role_access_gate.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_role_access_settings.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    TenantRoleAccessGate.reset();
  });

  test('doctor can edit appointments by default matrix', () {
    AuthSession.setUser(
      AppUser(
        id: 'doc-1',
        username: 'doc1',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );

    expect(AuthSession.canEditAppointments, isTrue);
    expect(AuthSession.canViewOwnScopedAppointments, isTrue);
  });

  test('maintenance override can revoke doctor appointment edit', () {
    AuthSession.setUser(
      AppUser(
        id: 'doc-1',
        username: 'doc1',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );

    TenantRoleAccessGate.apply(
      TenantRoleAccessSettings.empty().copyWithFlag(
        AppRoles.doctor,
        TenantRoleAccessKey.editAppointments,
        false,
      ),
    );

    expect(AuthSession.canEditAppointments, isFalse);
  });

  test('nurse cannot view or edit radiology orders by default', () {
    expect(
      TenantRoleAccessDefaults.forRole(
        AppRoles.nurse,
        TenantRoleAccessKey.viewRadiologyOrders,
      ),
      isFalse,
    );
    expect(
      TenantRoleAccessDefaults.forRole(
        AppRoles.nurse,
        TenantRoleAccessKey.editRadiologyOrders,
      ),
      isFalse,
    );
  });

  test('assistant can view but not edit radiology orders by default', () {
    expect(
      TenantRoleAccessDefaults.forRole(
        AppRoles.assistant,
        TenantRoleAccessKey.viewRadiologyOrders,
      ),
      isTrue,
    );
    expect(
      TenantRoleAccessDefaults.forRole(
        AppRoles.assistant,
        TenantRoleAccessKey.editRadiologyOrders,
      ),
      isFalse,
    );
  });

  test('physiotherapist can create payments by default', () {
    expect(
      TenantRoleAccessDefaults.forRole(
        AppRoles.physiotherapist,
        TenantRoleAccessKey.createPayments,
      ),
      isTrue,
    );
    expect(
      TenantRoleAccessDefaults.forRole(
        AppRoles.physiotherapist,
        TenantRoleAccessKey.viewPayments,
      ),
      isTrue,
    );
  });
}
