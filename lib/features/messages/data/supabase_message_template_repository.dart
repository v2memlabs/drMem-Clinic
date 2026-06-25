import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/active_tenant_context_sync.dart';
import '../models/message_template.dart';
import 'async_message_template_repository_contract.dart';
import 'message_repository.dart';
import 'message_template_remote_mapper.dart';
import 'message_template_repository_error_mapper.dart';
import 'message_template_repository_failure.dart';

class SupabaseMessageTemplateRepository
    implements AsyncMessageTemplateRepositoryContract {
  SupabaseMessageTemplateRepository(this._client);

  factory SupabaseMessageTemplateRepository.fromSupabase() {
    return SupabaseMessageTemplateRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const MessageTemplateRepositoryException(
        MessageTemplateRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const MessageTemplateRepositoryException(
        MessageTemplateRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on MessageTemplateRepositoryException {
      rethrow;
    } catch (e) {
      throw MessageTemplateRepositoryErrorMapper.toException(e);
    }
  }

  String? _ownerProfileId() {
    final id = ActiveTenantContextStore.current?.profile.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  String? _ownerDisplayName() {
    final name = ActiveTenantContextStore.current?.profile.displayName;
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  Future<void> _syncTenantForWrite() async {
    try {
      await ActiveTenantContextSync.ensureSyncedBeforeWrite();
    } on ActiveTenantContextSyncException {
      throw const MessageTemplateRepositoryException(
        MessageTemplateRepositoryFailure.noActiveTenant,
      );
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(MessageTemplateRemoteMapper.table)
        .select(MessageTemplateRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<MessageTemplate> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => MessageTemplateRemoteMapper.fromRow(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<List<MessageTemplate>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final rows = await _activeQuery(tenantId).order(
        'created_at',
        ascending: false,
      );
      return _mapRows(rows);
    });
  }

  @override
  Future<MessageTemplate?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row =
          await _activeQuery(tenantId).eq('id', id.trim()).maybeSingle();
      if (row == null) return null;
      return MessageTemplateRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<MessageTemplate>> search(String query) async {
    final q = query.trim().toLowerCase();
    final all = await getAll();
    if (q.isEmpty) return all;
    return all
        .where((t) => MessageRepository.templateMatchesQuery(t, q))
        .toList();
  }

  @override
  Future<List<MessageTemplate>> getFiltered({
    String? query,
    String? channelFilter,
    String? categoryFilter,
    Channel? channelEnumFilter,
    Category? categoryEnumFilter,
    bool activeOnly = false,
  }) async {
    Iterable<MessageTemplate> list;
    final q = query?.trim() ?? '';

    if (q.isNotEmpty) {
      final all = await getAll();
      final lower = q.toLowerCase();
      list = all.where((t) => MessageRepository.templateMatchesQuery(t, lower));
    } else {
      list = await getAll();
    }

    if (activeOnly) {
      list = list.where((t) => t.isActive);
    }
    if (channelEnumFilter != null) {
      list = list.where((t) => t.channel == channelEnumFilter);
    } else if (channelFilter != null && channelFilter.isNotEmpty) {
      final cf = channelFilter.toLowerCase();
      list = list.where((t) => t.channelLabel.toLowerCase().contains(cf));
    }
    if (categoryEnumFilter != null) {
      list = list.where((t) => t.category == categoryEnumFilter);
    } else if (categoryFilter != null && categoryFilter.isNotEmpty) {
      final cat = categoryFilter.toLowerCase();
      list = list.where((t) => t.categoryLabel.toLowerCase().contains(cat));
    }

    return List<MessageTemplate>.from(list);
  }

  @override
  Future<MessageTemplate> create(MessageTemplate template) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      final row = MessageTemplateRemoteMapper.toInsertRow(
        tenantId: tenantId,
        template: template,
        createdByProfileId: _ownerProfileId(),
        createdByDisplay: _ownerDisplayName() ?? template.createdBy,
      );

      final inserted = await _client
          .from(MessageTemplateRemoteMapper.table)
          .insert(row)
          .select(MessageTemplateRemoteMapper.listSelectColumns)
          .single();

      return MessageTemplateRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }

  @override
  Future<MessageTemplate> update(MessageTemplate template) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      final id = template.id.trim();
      if (id.isEmpty) {
        throw const MessageTemplateRepositoryException(
          MessageTemplateRepositoryFailure.notFound,
        );
      }

      final updated = await _client
          .from(MessageTemplateRemoteMapper.table)
          .update(MessageTemplateRemoteMapper.toUpdateRow(template))
          .eq('id', id)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select(MessageTemplateRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const MessageTemplateRepositoryException(
          MessageTemplateRepositoryFailure.notFound,
        );
      }

      return MessageTemplateRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }
}
