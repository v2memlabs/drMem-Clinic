import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/repository_registry.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../clinical_encounter/data/mock_clinical_encounters.dart';
import '../models/clinical_encounter_charge_option.dart';

/// Malzeme şarjı muayene listesi — tam muayene erişimi gerektirmez.
abstract final class ClinicalEncounterMaterialChargeDataSource {
  static const String listRpcName = 'list_patient_encounters_for_material_charge';

  static Future<List<ClinicalEncounterChargeOption>> listForPatient(
    String patientId,
  ) async {
    if (!AuthSession.canChargePatientMaterials) return const [];

    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    if (RepositoryRegistry.usesRemoteClinicalEncounters) {
      return _listRemote(pid);
    }
    return _listMock(pid);
  }

  static List<ClinicalEncounterChargeOption> _listMock(String patientId) {
    final options = mockClinicalEncounters
        .where((e) => e.patientId == patientId)
        .map(
          (e) => ClinicalEncounterChargeOption(
            id: e.id,
            patientId: e.patientId,
            patientName: e.patientName,
            encounterDate: e.createdAt,
            protocolNumber: e.protocolNumber,
          ),
        )
        .toList();
    options.sort((a, b) => b.encounterDate.compareTo(a.encounterDate));
    return options;
  }

  static Future<List<ClinicalEncounterChargeOption>> _listRemote(
    String patientId,
  ) async {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      return const [];
    }
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) return const [];

    try {
      final rows = await Supabase.instance.client.rpc(
        listRpcName,
        params: {'p_patient_id': patientId},
      );
      if (rows is! List) return const [];

      final options = <ClinicalEncounterChargeOption>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        final id = map['encounter_id']?.toString();
        final pid = map['patient_id']?.toString();
        final name = map['patient_display_name']?.toString().trim();
        if (id == null ||
            id.isEmpty ||
            pid == null ||
            pid.isEmpty ||
            name == null ||
            name.isEmpty) {
          continue;
        }
        final dateRaw = map['encounter_date']?.toString();
        final date = dateRaw == null ? null : DateTime.tryParse(dateRaw);
        if (date == null) continue;

        options.add(
          ClinicalEncounterChargeOption(
            id: id,
            patientId: pid,
            patientName: name,
            encounterDate: date,
            protocolNumber: map['protocol_number']?.toString(),
          ),
        );
      }
      options.sort((a, b) => b.encounterDate.compareTo(a.encounterDate));
      return options;
    } catch (_) {
      return const [];
    }
  }
}
