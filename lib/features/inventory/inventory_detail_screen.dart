import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/data_list_card.dart';
import '../../shared/widgets/clinical_stacked_sections.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/inventory_detail_data_source.dart';
import 'data/inventory_detail_load_result.dart';
import 'data/inventory_detail_user_messages.dart';
import 'data/inventory_list_refresh.dart';
import 'data/inventory_repository.dart';
import 'models/inventory_item.dart';
import 'models/inventory_movement.dart';
import '../payments/widgets/patient_material_charge_dialog.dart';
import 'widgets/inventory_movement_dialog.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String id;

  const InventoryDetailScreen({super.key, required this.id});

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  late Future<InventoryDetailLoadResult> _loadFuture;
  InventoryDetailLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = InventoryListRefresh.version;

  @override
  void initState() {
    super.initState();
    _reload();
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
    }
  }

  void _reload() {
    _lastRefreshVersion = InventoryListRefresh.version;
    setState(() {
      _loadFuture = InventoryDetailDataSource.loadById(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InventoryDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return AppShell(
            title: 'Stok Detayı',
            child: ClinicalStateMessage.loading(
              message: InventoryDetailUserMessages.loading,
            ),
          );
        }

        if (result != null && !result.hasError && result.item != null) {
          _cachedResult = result;
        }

        final active = _cachedResult ?? result;
        if (active == null) {
          return AppShell(
            title: 'Stok Detayı',
            child: ClinicalStateMessage.loading(
              message: InventoryDetailUserMessages.loading,
            ),
          );
        }

        if (active.hasError) {
          return AppShell(
            title: 'Stok Detayı',
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: InventoryDetailUserMessages.errorTitle,
              description: ClinicalStateMessage.safeErrorDescription(
                active.errorMessage,
              ),
              onRetry: _reload,
            ),
          );
        }

        if (active.notFound || active.item == null) {
          return AppShell(
            title: 'Stok Detayı',
            child: ClinicalStateMessage.empty(
              icon: Icons.error_outline,
              title: InventoryDetailUserMessages.notFoundTitle,
              description: InventoryDetailUserMessages.notFoundDescription,
            ),
          );
        }

        return _buildContent(context, active.item!, active.movements);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    InventoryItem item,
    List<InventoryMovement> movements,
  ) {
    final alerts = _buildAlerts(item);

    return AppShell(
      title: 'Stok Detayı',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Stok Detayı',
              icon: Icons.inventory_2_outlined,
              leadingBack: true,
              fallbackRoute: '/inventory',
            ),
            DetailHeaderCard(
              title: item.name,
              subtitle:
                  '${inventoryCategoryLabel(item.category)} • ${_formatQty(item.currentQuantity)} ${item.unit}',
            ),
            ClinicalStackedSections(
              children: [
                InfoSectionCard(
                  title: 'Stok Bilgisi',
                  rows: [
                    InfoSectionRow('Ad', item.name, emphasize: true),
                    InfoSectionRow(
                      'Kategori',
                      inventoryCategoryLabel(item.category),
                    ),
                    InfoSectionRow(
                      'Mevcut miktar',
                      '${_formatQty(item.currentQuantity)} ${item.unit}',
                      emphasize: true,
                    ),
                    InfoSectionRow(
                      'Minimum stok',
                      '${_formatQty(item.minimumQuantity)} ${item.unit}',
                    ),
                    InfoSectionRow('Birim', item.unit),
                    InfoSectionRow('Lokasyon', _display(item.location)),
                    InfoSectionRow(
                      'Son kullanma',
                      item.expirationDate != null
                          ? _formatDate(item.expirationDate!)
                          : kDisplayUnspecified,
                    ),
                    InfoSectionRow('Tedarikçi', _display(item.supplierName)),
                    InfoSectionRow(
                      'Durum',
                      item.isActive ? 'Aktif' : 'Pasif',
                    ),
                  ],
                ),
                if (alerts.isNotEmpty)
                  InfoSectionCard(
                    title: 'Uyarılar',
                    rows: alerts
                        .map((a) => InfoSectionRow('Uyarı', a, emphasize: true))
                        .toList(),
                  ),
                if ((item.notes ?? '').trim().isNotEmpty)
                  InfoSectionCard(
                    title: 'Notlar',
                    rows: [
                      InfoSectionRow('Not', item.notes!.trim()),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Stok Hareketleri',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (movements.isEmpty)
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Henüz stok hareketi kaydı yok.'),
                ),
              )
            else
              ...movements.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _movementCard(m),
                ),
              ),
            DetailActionsPanel(
              topSpacing: 0,
              actions: [
                if (AuthSession.canEditInventory)
                  DetailAction(
                    label: 'Düzenle',
                    onPressed: () => context.push('/inventory/${item.id}/edit'),
                  ),
                if (AuthSession.canRecordInventoryMovement)
                  DetailAction(
                    label: 'Stok Hareketi Ekle',
                    filled: true,
                    onPressed: () async {
                      final ok = await showInventoryMovementDialog(
                        context: context,
                        item: item,
                      );
                      if (ok && mounted) {
                        InventoryListRefresh.markStale();
                        _reload();
                      }
                    },
                  ),
                if (AuthSession.canChargePatientMaterials)
                  DetailAction(
                    label: 'Hastaya Malzeme Şarjı',
                    onPressed: () async {
                      final ok = await showPatientMaterialChargeDialog(
                        context: context,
                        item: item,
                      );
                      if (ok && mounted) {
                        InventoryListRefresh.markStale();
                        _reload();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  List<String> _buildAlerts(InventoryItem item) {
    final list = <String>[];
    if (InventoryRepository.isExpired(item)) list.add('SKT geçmiş');
    if (InventoryRepository.isLowStock(item)) list.add('Düşük stok');
    if (InventoryRepository.isExpiringSoon(item) &&
        !InventoryRepository.isExpired(item)) {
      list.add('SKT yakın (30 gün)');
    }
    return list;
  }

  Widget _movementCard(InventoryMovement m) {
    final subtitle =
        '${inventoryMovementTypeLabel(m.movementType)} • ${_formatQty(m.quantity)}';
    return DataListCard(
      title: _formatDate(m.movementDate),
      subtitle: subtitle,
      metaLine: m.performedBy,
      chips: [
        if (m.note != null && m.note!.trim().isNotEmpty) m.note!.trim(),
      ],
    );
  }

  String _display(String? v) {
    final t = v?.trim() ?? '';
    return t.isEmpty ? kDisplayUnspecified : t;
  }

  String _formatQty(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}';
  }
}
