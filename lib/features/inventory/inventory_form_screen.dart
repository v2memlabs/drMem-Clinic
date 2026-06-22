import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import 'data/inventory_form_data_source.dart';
import 'data/inventory_list_refresh.dart';
import 'data/inventory_list_user_messages.dart';
import 'models/inventory_item.dart';

class InventoryFormScreen extends StatefulWidget {
  final String? inventoryId;

  const InventoryFormScreen({super.key, this.inventoryId});

  bool get isEditMode =>
      inventoryId != null && inventoryId!.trim().isNotEmpty;

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _name = TextEditingController();
  final _unit = TextEditingController();
  final _currentQty = TextEditingController();
  final _minQty = TextEditingController();
  final _location = TextEditingController();
  final _supplier = TextEditingController();
  final _notes = TextEditingController();

  InventoryCategory _category = InventoryCategory.sarfMalzeme;
  DateTime? _expirationDate;
  bool _isActive = true;
  bool _loaded = false;
  bool _loadFailed = false;
  InventoryItem? _existingItem;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _loadEditItem();
    } else {
      _unit.text = 'adet';
      _currentQty.text = '0';
      _minQty.text = '0';
      _loaded = true;
    }
  }

  Future<void> _loadEditItem() async {
    final result = await InventoryFormDataSource.loadById(widget.inventoryId!);
    if (!mounted) return;

    if (result.notFound || result.item == null) {
      setState(() {
        _loadFailed = true;
        _loaded = true;
      });
      return;
    }

    if (result.hasError) {
      setState(() {
        _loadFailed = true;
        _loaded = true;
      });
      return;
    }

    final item = result.item!;
    _existingItem = item;
    _name.text = item.name;
    _unit.text = item.unit;
    _currentQty.text = _qtyText(item.currentQuantity);
    _minQty.text = _qtyText(item.minimumQuantity);
    _location.text = item.location ?? '';
    _supplier.text = item.supplierName ?? '';
    _notes.text = item.notes ?? '';
    _category = item.category;
    _expirationDate = item.expirationDate;
    _isActive = item.isActive;

    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _currentQty.dispose();
    _minQty.dispose();
    _location.dispose();
    _supplier.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _qtyText(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  Future<void> _pickExpiration() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  void _clearExpiration() => setState(() => _expirationDate = null);

  bool _validate() {
    if (_name.text.trim().isEmpty) {
      _snack('Stok adı zorunludur.');
      return false;
    }
    if (_unit.text.trim().isEmpty) {
      _snack('Birim zorunludur.');
      return false;
    }
    final current = double.tryParse(_currentQty.text.replaceAll(',', '.'));
    final minimum = double.tryParse(_minQty.text.replaceAll(',', '.'));
    if (current == null || current < 0) {
      _snack('Mevcut miktar geçerli ve negatif olmayan bir sayı olmalıdır.');
      return false;
    }
    if (minimum == null || minimum < 0) {
      _snack('Minimum stok geçerli ve negatif olmayan bir sayı olmalıdır.');
      return false;
    }
    return true;
  }

  void _snack(String msg, {bool isError = true}) {
    showClinicalSnackBar(context, msg, isError: isError);
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final now = DateTime.now();
    final current = double.parse(_currentQty.text.replaceAll(',', '.'));
    final minimum = double.parse(_minQty.text.replaceAll(',', '.'));

    if (widget.isEditMode) {
      final existing = _existingItem;
      if (existing == null) {
        _snack('Stok kartı bulunamadı.');
        return;
      }
      final updated = existing.copyWith(
        name: _name.text.trim(),
        category: _category,
        unit: _unit.text.trim(),
        currentQuantity: current,
        minimumQuantity: minimum,
        expirationDate: _expirationDate,
        clearExpirationDate: _expirationDate == null,
        location: _location.text.trim(),
        supplierName: _supplier.text.trim(),
        notes: _notes.text.trim(),
        isActive: _isActive,
        updatedAt: now,
      );
      final result = await InventoryFormDataSource.update(updated);
      if (!mounted) return;
      if (result.hasError) {
        _snack(result.errorMessage!);
        return;
      }
      InventoryListRefresh.markStale();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok kartı güncellendi.')),
      );
      context.go('/inventory/${updated.id}');
      return;
    }

    final item = InventoryItem(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      unit: _unit.text.trim(),
      currentQuantity: current,
      minimumQuantity: minimum,
      expirationDate: _expirationDate,
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      supplierName:
          _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    final result = await InventoryFormDataSource.add(item);
    if (!mounted) return;
    if (result.hasError) {
      _snack(result.errorMessage!);
      return;
    }
    InventoryListRefresh.markStale();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stok kartı oluşturuldu.')),
    );
    context.go('/inventory/${result.item!.id}');
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/inventory');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const AppShell(
        title: 'Stok Kartı',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.isEditMode && _loadFailed) {
      return AppShell(
        title: 'Stok Kartı',
        child: ClinicalStateMessage.error(
          icon: Icons.inventory_2_outlined,
          title: InventoryListUserMessages.errorTitle,
          description: InventoryListUserMessages.genericLoadFailure,
        ),
      );
    }

    return ClinicalFormScaffold.sections(
      shellTitle: widget.isEditMode ? 'Stok Düzenle' : 'Yeni Stok Kartı',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: widget.isEditMode ? 'Kaydet' : 'Oluştur',
      header: PageHeader(
        title: widget.isEditMode ? 'Stok Düzenle' : 'Yeni Stok Kartı',
        icon: Icons.inventory_2_outlined,
        leadingBack: true,
        fallbackRoute: '/inventory',
      ),
      sections: [
                        FormSectionCard(
                          title: 'Temel Bilgiler',
                          icon: Icons.inventory_2_outlined,
                          children: [
                            TextField(
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Stok adı *',
                                isDense: true,
                              ),
                            ),
                            DropdownButtonFormField<InventoryCategory>(
                              value: _category,
                              decoration: const InputDecoration(
                                labelText: 'Kategori *',
                                isDense: true,
                              ),
                              isExpanded: true,
                              items: InventoryCategory.values
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        inventoryCategoryLabel(c),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _category = v);
                              },
                            ),
                            TextField(
                              controller: _unit,
                              decoration: const InputDecoration(
                                labelText: 'Birim *',
                                isDense: true,
                              ),
                            ),
                            LayoutBuilder(
                              builder: (context, rowConstraints) {
                                final stacked = rowConstraints.maxWidth < 480;
                                final currentField = TextField(
                                  controller: _currentQty,
                                  decoration: const InputDecoration(
                                    labelText: 'Mevcut miktar *',
                                    isDense: true,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                );
                                final minField = TextField(
                                  controller: _minQty,
                                  decoration: const InputDecoration(
                                    labelText: 'Minimum stok *',
                                    isDense: true,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                );
                                if (stacked) {
                                  return Column(
                                    children: [currentField, minField],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: currentField),
                                    const SizedBox(width: 12),
                                    Expanded(child: minField),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        FormSectionCard(
                          title: 'Depolama',
                          icon: Icons.warehouse_outlined,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Son kullanma tarihi'),
                              subtitle: Text(
                                _expirationDate != null
                                    ? _formatDate(_expirationDate!)
                                    : 'Belirtilmedi',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_expirationDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: _clearExpiration,
                                      tooltip: 'SKT temizle',
                                    ),
                                  const Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                              onTap: _pickExpiration,
                            ),
                            TextField(
                              controller: _location,
                              decoration: const InputDecoration(
                                labelText: 'Lokasyon',
                                isDense: true,
                              ),
                            ),
                            TextField(
                              controller: _supplier,
                              decoration: const InputDecoration(
                                labelText: 'Tedarikçi',
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                        FormSectionCard(
                          title: 'Notlar',
                          icon: Icons.notes_outlined,
                          children: [
                            TextField(
                              controller: _notes,
                              decoration: const InputDecoration(
                                labelText: 'Not',
                                isDense: true,
                              ),
                              maxLines: 3,
                            ),
                            if (widget.isEditMode)
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Aktif stok kartı'),
                                value: _isActive,
                                onChanged: (v) => setState(() => _isActive = v),
                              ),
                          ],
                        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}';
  }
}
