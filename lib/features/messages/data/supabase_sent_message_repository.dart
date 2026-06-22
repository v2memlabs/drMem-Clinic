import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/sent_message.dart';
import 'async_sent_message_repository_contract.dart';
import 'message_repository.dart';
import 'sent_message_remote_mapper.dart';
import 'sent_message_repository_error_mapper.dart';
import 'sent_message_repository_failure.dart';

class SupabaseSentMessageRepository
    implements AsyncSentMessageRepositoryContract {
  SupabaseSentMessageRepository(this._client);

  factory SupabaseSentMessageRepository.fromSupabase() {
    return SupabaseSentMessageRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const SentMessageRepositoryException(
        SentMessageRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const SentMessageRepositoryException(
        SentMessageRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String? _sentByProfileId() {
    final id = ActiveTenantContextStore.current?.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  String? _sentByDisplay() {
    final name = ActiveTenantContextStore.current?.profile.displayName;
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on SentMessageRepositoryException {
      rethrow;
    } catch (e) {
      throw SentMessageRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(SentMessageRemoteMapper.table)
        .select(SentMessageRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<SentMessage> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => SentMessageRemoteMapper.fromRow(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<SentMessage>> _fetchOrdered(
    String tenantId,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    final query = build(_activeQuery(tenantId));
    final rows = await query.order('sent_at', ascending: false);
    return _mapRows(rows);
  }

  @override
  Future<List<SentMessage>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<SentMessage>> getByPatientId(String patientId) async {
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
  Future<SentMessage?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row =
          await _activeQuery(tenantId).eq('id', id.trim()).maybeSingle();
      if (row == null) return null;
      return SentMessageRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<SentMessage>> getFiltered({
    String? patientId,
    String? query,
    String? channelFilter,
    String? statusFilter,
    String? categoryFilter,
    SendStatus? statusEnumFilter,
  }) async {
    Iterable<SentMessage> list;
    final q = query?.trim() ?? '';

    if (q.isNotEmpty) {
      final all = await getAll();
      final lower = q.toLowerCase();
      list = all.where((m) => MessageRepository.sentMessageMatchesQuery(m, lower));
    } else if (patientId != null && patientId.trim().isNotEmpty) {
      list = await getByPatientId(patientId.trim());
    } else {
      list = await getAll();
    }

    if (channelFilter != null && channelFilter.isNotEmpty) {
      final cf = channelFilter.toLowerCase();
      list = list.where((m) => m.channel.toLowerCase().contains(cf));
    }
    if (statusEnumFilter != null) {
      list = list.where((m) => m.status == statusEnumFilter);
    } else if (statusFilter != null && statusFilter.isNotEmpty) {
      final sf = statusFilter.toLowerCase();
      list = list.where((m) => m.status.name.toLowerCase().contains(sf));
    }
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      final cat = categoryFilter.toLowerCase();
      list = list.where((m) => m.category.toLowerCase().contains(cat));
    }

    return List<SentMessage>.from(list);
  }

  @override
  Future<SentMessage> create(
    SentMessage message, {
    String? templateId,
    String? patientEmail,
    String? fullContent,
  }) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = SentMessageRemoteMapper.toInsertRow(
        tenantId: tenantId,
        message: message,
        templateId: templateId,
        sentByProfileId: _sentByProfileId(),
        sentByDisplay: _sentByDisplay(),
        patientEmail: patientEmail,
        content: fullContent ?? message.contentPreview,
      );

      final inserted = await _client
          .from(SentMessageRemoteMapper.table)
          .insert(row)
          .select(SentMessageRemoteMapper.listSelectColumns)
          .single();

      return SentMessageRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }
}
