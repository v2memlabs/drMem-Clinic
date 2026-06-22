import 'package:flutter/material.dart';

import '../data/inventory_repository.dart';
import '../models/inventory_item.dart';
import '../../../shared/widgets/clinical_list_status_tones.dart';
import '../../../shared/widgets/data_list_card.dart';

class InventoryClinicalListRow extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const InventoryClinicalListRow({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final alert = InventoryRepository.stockAlertLabel(item);
    final alertTone = ClinicalListStatusTones.inventoryAlertTone(item);
    final marker = alertTone != null
        ? ClinicalListStatusTones.markerColorForTone(alertTone)
        : null;
    final showChip = ClinicalListStatusTones.shouldShowInventoryAlertChip(item);

    final meta = <String>[
      inventoryCategoryLabel(item.category),
      'Min: ${_formatQty(item.minimumQuantity)} ${item.unit}',
    ];
    final loc = item.location?.trim();
    if (loc != null && loc.isNotEmpty) {
      meta.add(loc);
    }
    if (item.expirationDate != null) {
      meta.add('SKT: ${_formatDate(item.expirationDate!)}');
    }

    final trailing = item.expirationDate != null
        ? _formatDate(item.expirationDate!)
        : '${_formatQty(item.currentQuantity)} ${item.unit}';

    return DataListCard(
      title: item.name,
      subtitle:
          '${_formatQty(item.currentQuantity)} ${item.unit} · Min ${_formatQty(item.minimumQuantity)}',
      metaLine: meta.isNotEmpty ? meta.first : null,
      contextLine: meta.length > 1 ? meta.sublist(1).join(' • ') : null,
      accentRailColor: marker,
      semanticChipLabel: showChip && alert != null ? alert : null,
      semanticChipTone: alertTone != null
          ? ClinicalListStatusTones.inventoryAlertChipTone(item)
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  static String _formatQty(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}';
  }
}
