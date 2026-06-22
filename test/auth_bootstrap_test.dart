import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/active_tenant_selector.dart';
import 'package:v2mem_clinic/core/auth/auth_bootstrap_mapper.dart';
import 'package:v2mem_clinic/core/auth/auth_failure_reason.dart';
import 'package:v2mem_clinic/core/auth/session_bootstrap.dart';
import 'package:v2mem_clinic/core/auth/tenant_role_mapper.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';

void main() {
  group('TenantRoleMapper', () {
    test('maps all four seed roles both directions', () {
      const pairs = [
        (AppRoles.doctor, TenantRoleMapper.dbDoctorAdmin),
        (AppRoles.assistant, TenantRoleMapper.dbAssistantSecretary),
        (AppRoles.physiotherapist, TenantRoleMapper.dbPhysiotherapist),
        (AppRoles.nurse, TenantRoleMapper.dbNurse),
      ];
      for (final pair in pairs) {
        expect(TenantRoleMapper.toDbRole(pair.$1), pair.$2);
        expect(TenantRoleMapper.toFlutterRole(pair.$2), pair.$1);
      }
    });
  });

  group('ActiveTenantSelector', () {
    const profile = AuthenticatedProfile(
      profileId: 'p1',
      displayName: 'Test',
      email: 'doctor@example.test',
    );

    AuthenticatedMembership membership({
      required String dbRole,
      String status = 'active',
      String tenantStatus = 'active',
      String tenantId = 't1',
    }) {
      final flutter = TenantRoleMapper.toFlutterRole(dbRole)!;
      return AuthenticatedMembership(
        membershipId: 'm-$dbRole',
        tenantId: tenantId,
        tenantName: 'DrMem Test Klinik',
        tenantSpecialty: 'Ortopedi',
        dbRole: dbRole,
        flutterRole: flutter,
        status: status,
        tenantStatus: tenantStatus,
      );
    }

    test('single active membership → ready with correct dashboard role', () async {
      final result = ActiveTenantSelector.resolve(
        profile: profile,
        memberships: [membership(dbRole: TenantRoleMapper.dbDoctorAdmin)],
      );
      expect(result.status, SessionBootstrapStatus.ready);
      expect(result.context?.activeFlutterRole, AppRoles.doctor);
    });

    test('assistant_secretary → assistant dashboard role', () {
      final result = ActiveTenantSelector.resolve(
        profile: profile,
        memberships: [membership(dbRole: TenantRoleMapper.dbAssistantSecretary)],
      );
      expect(result.context?.activeFlutterRole, AppRoles.assistant);
    });

    test('physiotherapist and nurse roles', () {
      final physio = ActiveTenantSelector.resolve(
        profile: profile,
        memberships: [membership(dbRole: TenantRoleMapper.dbPhysiotherapist)],
      );
      expect(physio.context?.activeFlutterRole, AppRoles.physiotherapist);

      final nurse = ActiveTenantSelector.resolve(
        profile: profile,
        memberships: [membership(dbRole: TenantRoleMapper.dbNurse)],
      );
      expect(nurse.context?.activeFlutterRole, AppRoles.nurse);
    });

    test('no membership', () {
      final result = ActiveTenantSelector.resolve(profile: profile, memberships: []);
      expect(result.status, SessionBootstrapStatus.noMembership);
    });

    test('inactive membership', () {
      final result = ActiveTenantSelector.resolve(
        profile: profile,
        memberships: [
          membership(dbRole: TenantRoleMapper.dbDoctorAdmin, status: 'disabled'),
        ],
      );
      expect(result.status, SessionBootstrapStatus.inactiveMembership);
    });

    test('invited membership', () {
      final result = ActiveTenantSelector.resolve(
        profile: profile,
        memberships: [
          membership(dbRole: TenantRoleMapper.dbDoctorAdmin, status: 'invited'),
        ],
      );
      expect(result.status, SessionBootstrapStatus.inactiveMembership);
    });

    test('inactive tenant', () {
      final result = ActiveTenantSelector.resolve(
        profile: profile,
        memberships: [
          membership(
            dbRole: TenantRoleMapper.dbDoctorAdmin,
            tenantStatus: 'suspended',
          ),
        ],
      );
      expect(result.status, SessionBootstrapStatus.inactiveTenant);
    });

    test('unknown role — no doctor fallback', () {
      final result = ActiveTenantSelector.resolve(
        profile: profile,
        memberships: [
          AuthenticatedMembership(
            membershipId: 'm1',
            tenantId: 't1',
            tenantName: 'Klinik',
            dbRole: 'superadmin',
            flutterRole: 'doctor',
            status: 'active',
            tenantStatus: 'active',
          ),
        ],
      );
      expect(result.status, SessionBootstrapStatus.unknownRole);
    });

    test('multiple active memberships → needsTenantSelection', () {
      final result = ActiveTenantSelector.resolve(
        profile: profile,
        memberships: [
          membership(dbRole: TenantRoleMapper.dbDoctorAdmin, tenantId: 't1'),
          membership(dbRole: TenantRoleMapper.dbNurse, tenantId: 't2'),
        ],
      );
      expect(result.status, SessionBootstrapStatus.needsTenantSelection);
    });
  });

  group('Supabase login user messages', () {
    test('non-technical failure copy', () {
      expect(
        AuthFailureReasonMessage.forSupabaseLogin(AuthFailureReason.invalidCredentials),
        'Giriş bilgileri doğrulanamadı.',
      );
      expect(
        AuthFailureReasonMessage.forSupabaseLogin(AuthFailureReason.noMembership),
        'Bu kullanıcı için aktif klinik üyeliği bulunamadı.',
      );
      expect(
        AuthFailureReasonMessage.forSupabaseLogin(AuthFailureReason.inactiveTenant),
        'Klinik hesabı aktif değil.',
      );
      expect(
        AuthFailureReasonMessage.forSupabaseLogin(AuthFailureReason.unknownRole),
        'Rol bilgisi tanınamadı.',
      );
      expect(
        AuthFailureReasonMessage.forSupabaseLogin(AuthFailureReason.multipleMemberships),
        'Klinik seçimi sonraki sürümde aktif edilecektir.',
      );
      expect(
        AuthBootstrapMapper.userMessage(SessionBootstrapStatus.needsTenantSelection),
        'Klinik seçimi sonraki sürümde aktif edilecektir.',
      );
    });
  });
}
