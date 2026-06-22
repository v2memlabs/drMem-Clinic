import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/core/tenant/tenant_role_access_gate.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/mock_clinical_encounters.dart';
import 'package:v2mem_clinic/features/payments/data/clinical_encounter_material_charge_data_source.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_role_access_settings.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    TenantRoleAccessGate.reset();
  });

  test('nurse lists patient encounters for material charge without full CE access', () async {
    AuthSession.setUser(
      AppUser(
        id: 'nurse-1',
        username: 'nurse1',
        displayName: 'Hemşire',
        role: AppRoles.nurse,
      ),
    );

    final patientId = mockClinicalEncounters.first.patientId;
    final options =
        await ClinicalEncounterMaterialChargeDataSource.listForPatient(
      patientId,
    );

    expect(options, isNotEmpty);
    expect(options.every((o) => o.patientId == patientId), isTrue);
  });

  test('material charge list is empty without charge permission', () async {
    AuthSession.setUser(
      AppUser(
        id: 'guest-1',
        username: 'guest',
        displayName: 'Guest',
        role: AppRoles.assistant,
      ),
    );

    TenantRoleAccessGate.apply(
      TenantRoleAccessSettings.empty().copyWithFlag(
        AppRoles.assistant,
        TenantRoleAccessKey.chargePatientMaterials,
        false,
      ),
    );

    final patientId = mockClinicalEncounters.first.patientId;
    final options =
        await ClinicalEncounterMaterialChargeDataSource.listForPatient(
      patientId,
    );

    expect(options, isEmpty);
  });
}
