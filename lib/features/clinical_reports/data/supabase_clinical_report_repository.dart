import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/clinical_report.dart';
import 'async_clinical_report_repository_contract.dart';
import 'clinical_report_remote_mapper.dart';
import 'clinical_report_repository.dart';
import 'clinical_report_repository_error_mapper.dart';
import 'clinical_report_repository_failure.dart';

class SupabaseClinicalReportRepository
    implements AsyncClinicalReportRepositoryContract {
  SupabaseClinicalReportRepository(this._client);

  factory SupabaseClinicalReportRepository.fromSupabase() {
    return SupabaseClinicalReportRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.noActiveTenant,
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
    } on ClinicalReportRepositoryException {
      rethrow;
    } catch (e) {
      throw ClinicalReportRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(ClinicalReportRemoteMapper.table)
        .select(ClinicalReportRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<ClinicalReport> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => ClinicalReportRemoteMapper.fromRow(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<ClinicalReport>> _fetchOrdered(
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
  Future<List<ClinicalReport>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<ClinicalReport>> getByPatientId(String patientId) async {
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
  Future<ClinicalReport?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row =
          await _activeQuery(tenantId).eq('id', id.trim()).maybeSingle();
      if (row == null) return null;
      return ClinicalReportRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<ClinicalReport>> getFiltered({
    String? patientId,
    String? query,
    ClinicalReportType? typeFilter,
    ClinicalReportStatus? statusFilter,
  }) async {
    Iterable<ClinicalReport> list;
    final q = query?.trim() ?? '';

    if (q.isNotEmpty) {
      final all = await getAll();
      final lower = q.toLowerCase();
      list = all.where((r) => ClinicalReportRepository.matchesQuery(r, lower));
    } else if (patientId != null && patientId.trim().isNotEmpty) {
      list = await getByPatientId(patientId.trim());
    } else {
      list = await getAll();
    }

    if (typeFilter != null) {
      list = list.where((r) => r.reportType == typeFilter);
    }
    if (statusFilter != null) {
      list = list.where((r) => r.status == statusFilter);
    }
    return List<ClinicalReport>.from(list);
  }

  @override
  Future<ClinicalReport> create(ClinicalReport report) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = ClinicalReportRemoteMapper.toInsertRow(
        tenantId: tenantId,
        report: report,
        createdByProfileId: _createdByProfileId(),
        createdByDisplay: _createdByDisplay(),
      );

      final inserted = await _client
          .from(ClinicalReportRemoteMapper.table)
          .insert(row)
          .select(ClinicalReportRemoteMapper.listSelectColumns)
          .single();

      return ClinicalReportRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }

  @override
  Future<ClinicalReport> update(ClinicalReport report) async {
    if (report.id.trim().isEmpty) {
      throw const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.invalidRow,
      );
    }

    return _guard(() async {
      final tenantId = _requireTenantId();
      final updated = await _client
          .from(ClinicalReportRemoteMapper.table)
          .update(ClinicalReportRemoteMapper.toUpdateRow(report))
          .eq('tenant_id', tenantId)
          .eq('id', report.id.trim())
          .isFilter('deleted_at', null)
          .select(ClinicalReportRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const ClinicalReportRepositoryException(
          ClinicalReportRepositoryFailure.notFound,
        );
      }
      return ClinicalReportRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }
}
