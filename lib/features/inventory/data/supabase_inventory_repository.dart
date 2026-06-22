import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';
import 'async_inventory_repository_contract.dart';
import 'inventory_remote_mapper.dart';
import 'inventory_repository.dart';
import 'inventory_repository_error_mapper.dart';
import 'inventory_repository_failure.dart';

/// Supabase inventory — doctor_admin / nurse RLS; movement via RPC.
class SupabaseInventoryRepository implements AsyncInventoryRepositoryContract {
  SupabaseInventoryRepository(this._client);

  factory SupabaseInventoryRepository.fromSupabase() {
    return SupabaseInventoryRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const InventoryRepositoryException(
        InventoryRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const InventoryRepositoryException(
        InventoryRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String? _createdByProfileId() {
    final id = ActiveTenantContextStore.current?.profile.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on InventoryRepositoryException {
      rethrow;
    } catch (e) {
      throw InventoryRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeItemsQuery(
    String tenantId, {
    bool includeInactive = false,
  }) {
    var query = _client
        .from(InventoryRemoteMapper.itemsTable)
        .select(InventoryRemoteMapper.itemSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);

    if (!includeInactive) {
      query = query.eq('is_active', true);
    }
    return query;
  }

  List<InventoryItem> _applyClientFilters({
    required List<InventoryItem> items,
    String? query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
  }) {
    Iterable<InventoryItem> list = items;

    if (category != null) {
      list = list.where((e) => e.category == category);
    }
    if (lowStockOnly) {
      list = list.where(InventoryRepository.isLowStock);
    }
    if (expiringSoonOnly) {
      list = list.where((e) => InventoryRepository.isExpiringSoon(e));
    }
    if (expiredOnly) {
      list = list.where(InventoryRepository.isExpired);
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((e) => _matchesQuery(e, q));
    }

    final result = List<InventoryItem>.from(list);
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  bool _matchesQuery(InventoryItem item, String q) {
    if (item.name.toLowerCase().contains(q)) return true;
    if (inventoryCategoryLabel(item.category).toLowerCase().contains(q)) {
      return true;
    }
    if ((item.location ?? '').toLowerCase().contains(q)) return true;
    if ((item.supplierName ?? '').toLowerCase().contains(q)) return true;
    if ((item.notes ?? '').toLowerCase().contains(q)) return true;
    if (item.unit.toLowerCase().contains(q)) return true;
    return false;
  }

  Future<List<InventoryItem>> _fetchActiveItems({
    bool includeInactive = false,
  }) async {
    final tenantId = _requireTenantId();
    final rows = await _activeItemsQuery(
      tenantId,
      includeInactive: includeInactive,
    ).order('name');
    return rows
        .map((e) => InventoryRemoteMapper.itemFromRow(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<InventoryItem>> getFiltered({
    String? query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
    bool includeInactive = false,
  }) async {
    return _guard(() async {
      final items = await _fetchActiveItems(includeInactive: includeInactive);
      return _applyClientFilters(
        items: items,
        query: query,
        category: category,
        lowStockOnly: lowStockOnly,
        expiringSoonOnly: expiringSoonOnly,
        expiredOnly: expiredOnly,
      );
    });
  }

  @override
  Future<InventoryItem?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _client
          .from(InventoryRemoteMapper.itemsTable)
          .select(InventoryRemoteMapper.itemSelectColumns)
          .eq('tenant_id', tenantId)
          .eq('id', id.trim())
          .isFilter('deleted_at', null)
          .maybeSingle();
      if (row == null) return null;
      return InventoryRemoteMapper.itemFromRow(row);
    });
  }

  @override
  Future<InventoryItem> add(InventoryItem item) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = InventoryRemoteMapper.toInsertItemRow(
        tenantId: tenantId,
        item: item,
        createdByProfileId: _createdByProfileId(),
      );

      final inserted = await _client
          .from(InventoryRemoteMapper.itemsTable)
          .insert(row)
          .select(InventoryRemoteMapper.itemSelectColumns)
          .single();

      return InventoryRemoteMapper.itemFromRow(Map<String, dynamic>.from(inserted));
    });
  }

  @override
  Future<InventoryItem> update(InventoryItem item) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final id = item.id.trim();
      if (id.isEmpty) {
        throw const InventoryRepositoryException(
          InventoryRepositoryFailure.notFound,
        );
      }

      final updated = await _client
          .from(InventoryRemoteMapper.itemsTable)
          .update(InventoryRemoteMapper.toUpdateItemRow(item))
          .eq('id', id)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select(InventoryRemoteMapper.itemSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const InventoryRepositoryException(
          InventoryRepositoryFailure.notFound,
        );
      }

      return InventoryRemoteMapper.itemFromRow(Map<String, dynamic>.from(updated));
    });
  }

  @override
  Future<String?> addMovement(InventoryMovement movement) async {
    try {
      _ensureConfigured();
      _requireTenantId();
      await _client.rpc(
        'record_inventory_movement',
        params: InventoryRemoteMapper.movementRpcParams(movement),
      );
      return null;
    } on InventoryRepositoryException {
      rethrow;
    } catch (e) {
      final validation = InventoryRepositoryErrorMapper.toValidationMessage(e);
      if (validation != null) return validation;
      throw InventoryRepositoryErrorMapper.toException(e);
    }
  }

  @override
  Future<List<InventoryMovement>> getMovementsByItemId(
    String inventoryItemId,
  ) async {
    if (inventoryItemId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      final rows = await _client
          .from(InventoryRemoteMapper.movementsTable)
          .select(InventoryRemoteMapper.movementSelectColumns)
          .eq('tenant_id', tenantId)
          .eq('inventory_item_id', inventoryItemId.trim())
          .order('movement_date', ascending: false);

      return rows
          .map(
            (e) => InventoryRemoteMapper.movementFromRow(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    });
  }

  @override
  Future<int> countLowStock() async {
    return _guard(() async {
      final items = await _fetchActiveItems();
      return items.where(InventoryRepository.isLowStock).length;
    });
  }

  @override
  Future<int> countExpiringSoon({
    int days = InventoryRepository.defaultExpiringSoonDays,
  }) async {
    return _guard(() async {
      final items = await _fetchActiveItems();
      return items.where((e) => InventoryRepository.isExpiringSoon(e, days: days)).length;
    });
  }

  @override
  Future<int> countExpired() async {
    return _guard(() async {
      final items = await _fetchActiveItems();
      return items.where(InventoryRepository.isExpired).length;
    });
  }
}
