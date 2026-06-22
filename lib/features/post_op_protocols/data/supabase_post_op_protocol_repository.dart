import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/post_op_protocol.dart';
import 'async_post_op_protocol_repository_contract.dart';
import 'post_op_protocol_remote_mapper.dart';
import 'post_op_protocol_repository.dart';
import 'post_op_protocol_repository_error_mapper.dart';
import 'post_op_protocol_repository_failure.dart';

class SupabasePostOpProtocolRepository
    implements AsyncPostOpProtocolRepositoryContract {
  SupabasePostOpProtocolRepository(this._client);

  factory SupabasePostOpProtocolRepository.fromSupabase() {
    return SupabasePostOpProtocolRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PostOpProtocolRepositoryException(
        PostOpProtocolRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PostOpProtocolRepositoryException(
        PostOpProtocolRepositoryFailure.noActiveTenant,
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
    } on PostOpProtocolRepositoryException {
      rethrow;
    } catch (e) {
      throw PostOpProtocolRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(PostOpProtocolRemoteMapper.table)
        .select(PostOpProtocolRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<PostOpProtocol> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => PostOpProtocolRemoteMapper.fromRow(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<PostOpProtocol>> _fetchOrdered(
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
  Future<List<PostOpProtocol>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<PostOpProtocol>> getByPatientId(String patientId) async {
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
  Future<List<PostOpProtocol>> getBySurgeryNoteId(String surgeryNoteId) async {
    if (surgeryNoteId.trim().isEmpty) return const [];
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(
        tenantId,
        (q) => q.eq('surgery_note_id', surgeryNoteId.trim()),
      );
    });
  }

  @override
  Future<PostOpProtocol?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row =
          await _activeQuery(tenantId).eq('id', id.trim()).maybeSingle();
      if (row == null) return null;
      return PostOpProtocolRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<PostOpProtocol>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getAll();
    final all = await getAll();
    final lower = q.toLowerCase();
    return all
        .where((p) => PostOpProtocolRepository.matchesQuery(p, lower))
        .toList();
  }

  @override
  Future<List<PostOpProtocol>> getFiltered({
    String? patientId,
    String? surgeryNoteId,
    String? query,
    PostOpPhase? phaseFilter,
    PostOpProtocolStatus? statusFilter,
  }) async {
    Iterable<PostOpProtocol> list;
    final q = query?.trim() ?? '';

    if (q.isNotEmpty) {
      list = await search(q);
    } else if (surgeryNoteId != null && surgeryNoteId.trim().isNotEmpty) {
      list = await getBySurgeryNoteId(surgeryNoteId.trim());
    } else if (patientId != null && patientId.trim().isNotEmpty) {
      list = await getByPatientId(patientId.trim());
    } else {
      list = await getAll();
    }

    if (patientId != null && patientId.trim().isNotEmpty) {
      list = list.where((p) => p.patientId == patientId.trim());
    }
    if (surgeryNoteId != null && surgeryNoteId.trim().isNotEmpty) {
      list = list.where((p) => p.surgeryNoteId == surgeryNoteId.trim());
    }
    if (phaseFilter != null) {
      list = list.where((p) => p.phase == phaseFilter);
    }
    if (statusFilter != null) {
      list = list.where((p) => p.status == statusFilter);
    }
    return List<PostOpProtocol>.from(list);
  }

  @override
  Future<PostOpProtocol> create(PostOpProtocol protocol) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = PostOpProtocolRemoteMapper.toInsertRow(
        tenantId: tenantId,
        protocol: protocol,
        createdByProfileId: _createdByProfileId(),
        createdByDisplay: _createdByDisplay(),
      );

      final inserted = await _client
          .from(PostOpProtocolRemoteMapper.table)
          .insert(row)
          .select(PostOpProtocolRemoteMapper.listSelectColumns)
          .single();

      return PostOpProtocolRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }
}
