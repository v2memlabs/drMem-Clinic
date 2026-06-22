import 'package:flutter/material.dart';

import '../../../core/data/repository_registry.dart';
import '../../inventory/models/inventory_item.dart';
import '../../../shared/widgets/clinical_snack_bar.dart';
import 'patient_material_charge_dialog.dart';

/// Hasta detayından malzeme şarjı — stok kalemi seç, ardından şarj dialogu.
abstract final class PatientMaterialChargeLauncher {
  static Future<void> launch(
    BuildContext context, {
    required String patientId,
  }) async {
    List<InventoryItem> items;
    try {
      items = await RepositoryRegistry.inventoryAsync.getFiltered();
      items = items.where((i) => i.isActive && i.currentQuantity > 0).toList();
    } catch (_) {
      if (!context.mounted) return;
      showClinicalSnackBar(
        context,
        'Stok listesi yüklenemedi.',
        isError: true,
      );
      return;
    }

    if (!context.mounted) return;
    if (items.isEmpty) {
      showClinicalSnackBar(
        context,
        'Şarj için uygun stok kalemi bulunamadı.',
        isError: true,
      );
      return;
    }

    final selected = await showDialog<InventoryItem>(
      context: context,
      builder: (context) => _InventoryItemPickerDialog(items: items),
    );

    if (!context.mounted || selected == null) return;

    await showPatientMaterialChargeDialog(
      context: context,
      item: selected,
      patientId: patientId,
    );
  }
}

class _InventoryItemPickerDialog extends StatelessWidget {
  final List<InventoryItem> items;

  const _InventoryItemPickerDialog({required this.items});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Malzeme seçin'),
      content: SizedBox(
        width: 400,
        height: 320,
        child: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                'Stok: ${item.currentQuantity} ${item.unit}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              dense: true,
              onTap: () => Navigator.of(context).pop(item),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ],
    );
  }
}
