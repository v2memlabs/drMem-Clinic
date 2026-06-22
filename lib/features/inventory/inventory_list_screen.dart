import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/data/repository_registry.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_status_legend.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/inventory_list_data_source.dart';
import 'data/inventory_list_load_result.dart';
import 'data/inventory_list_refresh.dart';
import 'data/inventory_list_user_messages.dart';
import 'models/inventory_item.dart';
import 'widgets/inventory_clinical_list_row.dart';
import 'widgets/inventory_list_legend.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  String _query = '';
  InventoryCategory? _categoryFilter;
  bool _lowStockOnly = false;
  bool _expiringSoonOnly = false;
  bool _expiredOnly = false;
  late Future<InventoryListLoadResult> _loadFuture;
  InventoryListLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = InventoryListRefresh.version;
  int _lowStockCount = 0;
  int _expiringSoonCount = 0;
  int _expiredCount = 0;

  int get _inventoryActiveFilterCount {
    var n = 0;
    if (_categoryFilter != null) n++;
    if (_lowStockOnly) n++;
    if (_expiringSoonOnly) n++;
    if (_expiredOnly) n++;
    return n;
  }

  void _clearInventoryFilters() {
    setState(() {
      _categoryFilter = null;
      _lowStockOnly = false;
      _expiringSoonOnly = false;
      _expiredOnly = false;
    });
    _reload();
  }

  @override
  void initState() {
    super.initState();
    _reload();
    _loadBadgeCounts();
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (InventoryListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
      _loadBadgeCounts();
    }
  }

  Future<void> _loadBadgeCounts() async {
    try {
      final repo = RepositoryRegistry.inventoryAsync;
      final low = await repo.countLowStock();
      final expiring = await repo.countExpiringSoon();
      final expired = await repo.countExpired();
      if (!mounted) return;
      setState(() {
        _lowStockCount = low;
        _expiringSoonCount = expiring;
        _expiredCount = expired;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lowStockCount = 0;
        _expiringSoonCount = 0;
        _expiredCount = 0;
      });
    }
  }

  void _reload() {
    _lastRefreshVersion = InventoryListRefresh.version;
    setState(() {
      _loadFuture = InventoryListDataSource.load(
        query: _query,
        category: _categoryFilter,
        lowStockOnly: _lowStockOnly,
        expiringSoonOnly: _expiringSoonOnly,
        expiredOnly: _expiredOnly,
      );
    });
  }

  void _reloadIfStale() {
    if (InventoryListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
      _loadBadgeCounts();
    }
  }

  Future<void> _openInventoryDetail(String id) async {
    await context.push('/inventory/$id');
    if (mounted) _reloadIfStale();
  }

  Future<void> _openNewInventory() async {
    await context.push('/inventory/new');
    if (mounted) _reloadIfStale();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Stok / Sarf',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Stok / Sarf',
              icon: Icons.inventory_2_outlined,
            ),
            FilterBar(
              searchHint: 'Stok adı, kategori, lokasyon, tedarikçi veya not ara',
              onSearchChanged: (v) {
                _query = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _inventoryActiveFilterCount,
              onClearFilters:
                  _inventoryActiveFilterCount > 0 ? _clearInventoryFilters : null,
              trailing: AuthSession.canEditInventory
                  ? FilledButton.icon(
                      onPressed: _openNewInventory,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni Stok Kartı'),
                    )
                  : null,
              filters: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<InventoryCategory?>(
                    value: _categoryFilter,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tüm kategoriler'),
                      ),
                      ...InventoryCategory.values.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(inventoryCategoryLabel(c)),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _categoryFilter = v);
                      _reload();
                    },
                  ),
                ),
                FilterChip(
                  label: Text('Düşük stok ($_lowStockCount)'),
                  selected: _lowStockOnly,
                  onSelected: (v) {
                    setState(() {
                      _lowStockOnly = v;
                      if (v) {
                        _expiringSoonOnly = false;
                        _expiredOnly = false;
                      }
                    });
                    _reload();
                  },
                ),
                FilterChip(
                  label: Text('SKT yakın ($_expiringSoonCount)'),
                  selected: _expiringSoonOnly,
                  onSelected: (v) {
                    setState(() {
                      _expiringSoonOnly = v;
                      if (v) {
                        _lowStockOnly = false;
                        _expiredOnly = false;
                      }
                    });
                    _reload();
                  },
                ),
                FilterChip(
                  label: Text('SKT geçmiş ($_expiredCount)'),
                  selected: _expiredOnly,
                  onSelected: (v) {
                    setState(() {
                      _expiredOnly = v;
                      if (v) {
                        _lowStockOnly = false;
                        _expiringSoonOnly = false;
                      }
                    });
                    _reload();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<InventoryListLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return ClinicalStateMessage.loading(
            message: InventoryListUserMessages.loading,
          );
        }

        if (result != null && !result.hasError) {
          _cachedResult = result;
        }

        final active = result ?? _cachedResult;
        if (active == null) {
          return ClinicalStateMessage.loading(
            message: InventoryListUserMessages.loading,
          );
        }

        if (active.hasError) {
          return ClinicalStateMessage.error(
            icon: Icons.error_outline,
            title: InventoryListUserMessages.errorTitle,
            description: ClinicalStateMessage.safeErrorDescription(
              active.errorMessage,
            ),
            onRetry: _reload,
          );
        }

        final items = active.items;
        if (items.isEmpty) {
          return ClinicalStateMessage.empty(
            icon: Icons.inventory_2_outlined,
            title: 'Stok kartı bulunamadı',
            description:
                'Arama veya filtre kriterlerinize uygun kayıt yok.',
          );
        }

        return ClinicalSeparatedListBody(
          legend: const ClinicalStatusLegend(
            items: InventoryListLegend.items,
          ),
          children: [
            for (final item in items)
              InventoryClinicalListRow(
                item: item,
                onTap: () => _openInventoryDetail(item.id),
              ),
          ],
        );
      },
    );
  }
}
