import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/imaging_note.dart';
import 'async_imaging_repository_contract.dart';
import 'imaging_remote_mapper.dart';
import 'imaging_repository.dart';
import 'imaging_repository_error_mapper.dart';
import 'imaging_repository_failure.dart';

class SupabaseImagingRepository implements AsyncImagingRepositoryContract {
  SupabaseImagingRepository(this._client);

  factory SupabaseImagingRepository.fromSupabase() {
    return SupabaseImagingRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const ImagingRepositoryException(
        ImagingRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const ImagingRepositoryException(
        ImagingRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String? _createdByProfileId() {
    final id = ActiveTenantContextStore.current?.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  String? _recordedByDisplay() {
    final name = ActiveTenantContextStore.current?.profile.displayName;
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ImagingRepositoryException {
      rethrow;
    } catch (e) {
      throw ImagingRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(ImagingRemoteMapper.table)
        .select(ImagingRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<ImagingNote> _mapRows(List<dynamic> rows) {
    return rows
        .map((e) => ImagingRemoteMapper.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ImagingNote>> _fetchOrdered(
    String tenantId,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    final query = build(_activeQuery(tenantId));
    final rows = await query
        .order('imaging_date', ascending: false)
        .order('created_at', ascending: false);
    return _mapRows(rows);
  }

  @override
  Future<List<ImagingNote>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<ImagingNote>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q.eq('patient_id', patientId.trim()));
    });
  }

  @override
  Future<ImagingNote?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeQuery(tenantId)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return ImagingRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<ImagingNote>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getAll();
    final all = await getAll();
    final lower = q.toLowerCase();
    return all.where((n) => ImagingRepository.matchesQuery(n, lower)).toList();
  }

  @override
  Future<List<ImagingNote>> getFiltered({
    String? patientId,
    String? query,
    ImagingType? imagingTypeFilter,
    ImagingBodyRegion? bodyRegionFilter,
  }) async {
    Iterable<ImagingNote> list;
    final q = query?.trim() ?? '';

    if (q.isNotEmpty) {
      list = await search(q);
    } else if (patientId != null && patientId.trim().isNotEmpty) {
      list = await getByPatientId(patientId.trim());
    } else {
      list = await getAll();
    }

    if (imagingTypeFilter != null) {
      list = list.where((n) => n.imagingType == imagingTypeFilter);
    }
    if (bodyRegionFilter != null) {
      list = list.where((n) => n.bodyRegion == bodyRegionFilter);
    }

    return List<ImagingNote>.from(list);
  }

  @override
  Future<ImagingNote> create(ImagingNote note) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = ImagingRemoteMapper.toInsertRow(
        tenantId: tenantId,
        note: note,
        createdByProfileId: _createdByProfileId(),
        recordedByDisplay: _recordedByDisplay(),
      );

      final inserted = await _client
          .from(ImagingRemoteMapper.table)
          .insert(row)
          .select(ImagingRemoteMapper.listSelectColumns)
          .single();

      return ImagingRemoteMapper.fromRow(Map<String, dynamic>.from(inserted));
    });
  }
}
