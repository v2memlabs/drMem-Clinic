import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/prescription.dart';
import 'async_prescription_repository_contract.dart';
import 'prescription_remote_mapper.dart';
import 'prescription_repository.dart';
import 'prescription_repository_error_mapper.dart';
import 'prescription_repository_failure.dart';

class SupabasePrescriptionRepository
    implements AsyncPrescriptionRepositoryContract {
  SupabasePrescriptionRepository(this._client);

  factory SupabasePrescriptionRepository.fromSupabase() {
    return SupabasePrescriptionRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String? _createdByProfileId() {
    final id = ActiveTenantContextStore.current?.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  String? _createdByDisplay() {
    final name = ActiveTenantContextStore.current?.profile.displayName;
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PrescriptionRepositoryException {
      rethrow;
    } catch (e) {
      throw PrescriptionRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(PrescriptionRemoteMapper.table)
        .select(PrescriptionRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<Prescription> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => PrescriptionRemoteMapper.fromRow(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<Prescription>> _fetchOrdered(
    String tenantId,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    final query = build(_activeQuery(tenantId));
    final rows = await query.order('created_at', ascending: false);
    return _mapRows(rows);
  }

  @override
  Future<List<Prescription>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<Prescription>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(
        tenantId,
        (q) => q.eq('patient_id', patientId.trim()),
      );
    });
  }

  @override
  Future<Prescription?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row =
          await _activeQuery(tenantId).eq('id', id.trim()).maybeSingle();
      if (row == null) return null;
      return PrescriptionRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<Prescription>> getFiltered({
    String? patientId,
    String? query,
    PrescriptionStatus? statusFilter,
  }) async {
    Iterable<Prescription> list;
    final q = query?.trim() ?? '';

    if (q.isNotEmpty) {
      final all = await getAll();
      final lower = q.toLowerCase();
      list = all.where((p) => PrescriptionRepository.matchesQuery(p, lower));
    } else if (patientId != null && patientId.trim().isNotEmpty) {
      list = await getByPatientId(patientId.trim());
    } else {
      list = await getAll();
    }

    if (statusFilter != null) {
      list = list.where((p) => p.status == statusFilter);
    }
    return List<Prescription>.from(list);
  }

  @override
  Future<Prescription> create(Prescription prescription) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = PrescriptionRemoteMapper.toInsertRow(
        tenantId: tenantId,
        prescription: prescription,
        createdByProfileId: _createdByProfileId(),
        createdByDisplay: _createdByDisplay(),
      );

      final inserted = await _client
          .from(PrescriptionRemoteMapper.table)
          .insert(row)
          .select(PrescriptionRemoteMapper.listSelectColumns)
          .single();

      return PrescriptionRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }

  @override
  Future<Prescription> update(Prescription prescription) async {
    if (prescription.id.trim().isEmpty) {
      throw const PrescriptionRepositoryException(
        PrescriptionRepositoryFailure.invalidRow,
      );
    }

    return _guard(() async {
      final tenantId = _requireTenantId();
      final updated = await _client
          .from(PrescriptionRemoteMapper.table)
          .update(PrescriptionRemoteMapper.toUpdateRow(prescription))
          .eq('tenant_id', tenantId)
          .eq('id', prescription.id.trim())
          .isFilter('deleted_at', null)
          .select(PrescriptionRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const PrescriptionRepositoryException(
          PrescriptionRepositoryFailure.notFound,
        );
      }
      return PrescriptionRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }
}
