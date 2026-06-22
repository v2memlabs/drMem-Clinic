import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../shared/widgets/clinical_snack_bar.dart';
import '../data/inventory_form_data_source.dart';
import '../data/inventory_list_refresh.dart';
import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';

/// Stok hareketi ekleme dialogu.
Future<bool> showInventoryMovementDialog({
  required BuildContext context,
  required InventoryItem item,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _InventoryMovementDialog(item: item),
  );
  return result == true;
}

class _InventoryMovementDialog extends StatefulWidget {
  final InventoryItem item;

  const _InventoryMovementDialog({required this.item});

  @override
  State<_InventoryMovementDialog> createState() =>
      _InventoryMovementDialogState();
}

class _InventoryMovementDialogState extends State<_InventoryMovementDialog> {
  InventoryMovementType _type = InventoryMovementType.giris;
  final _quantityCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _movementDate = DateTime.now();

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _performedBy {
    final name = AuthSession.currentUser?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return AuthSession.currentUser?.displayName ?? 'Kullanıcı';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _movementDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _movementDate = picked);
  }

  Future<void> _save() async {
    final qty = double.tryParse(_quantityCtrl.text.replaceAll(',', '.'));
    if (qty == null || qty <= 0) {
      showClinicalSnackBar(
        context,
        'Miktar sıfırdan büyük olmalıdır.',
        isError: true,
      );
      return;
    }

    final movement = InventoryMovement(
      id: 'mov-${DateTime.now().millisecondsSinceEpoch}',
      inventoryItemId: widget.item.id,
      movementType: _type,
      quantity: qty,
      movementDate: _movementDate,
      performedBy: _performedBy,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final result = await InventoryFormDataSource.addMovement(movement);
    if (result.validationError != null) {
      showClinicalSnackBar(context, result.validationError!, isError: true);
      return;
    }
    if (result.hasError) {
      showClinicalSnackBar(context, result.repositoryError!, isError: true);
      return;
    }

    InventoryListRefresh.markStale();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final qtyHint = _type == InventoryMovementType.duzeltme
        ? 'Yeni stok miktarı (${widget.item.unit})'
        : 'Miktar (${widget.item.unit})';

    return AlertDialog(
      title: const Text('Stok Hareketi Ekle'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'Mevcut: ${_formatQty(widget.item.currentQuantity)} ${widget.item.unit}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InventoryMovementType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Hareket tipi',
                isDense: true,
              ),
              items: InventoryMovementType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(inventoryMovementTypeLabel(t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityCtrl,
              decoration: InputDecoration(
                labelText: qtyHint,
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hareket tarihi'),
              subtitle: Text(_formatDate(_movementDate)),
              trailing: const Icon(Icons.calendar_today, size: 20),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Kaydet'),
        ),
      ],
    );
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
