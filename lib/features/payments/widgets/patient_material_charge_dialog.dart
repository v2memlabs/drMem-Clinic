import 'package:flutter/material.dart';

import '../../inventory/models/inventory_item.dart';
import '../../patients/widgets/patient_selector_field.dart';
import '../data/clinical_encounter_material_charge_data_source.dart';
import '../data/patient_material_charge_orchestrator.dart';
import '../models/clinical_encounter_charge_option.dart';
import '../../../shared/widgets/clinical_notice.dart';
import '../../../shared/widgets/clinical_notice_tone.dart';
import '../../../shared/widgets/clinical_snack_bar.dart';

/// Hasta malzeme şarjı — seçili muayene + stok kalemi.
Future<bool> showPatientMaterialChargeDialog({
  required BuildContext context,
  required InventoryItem item,
  String? patientId,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _PatientMaterialChargeDialog(
      patientId: patientId,
      item: item,
    ),
  );
  return result == true;
}

class _PatientMaterialChargeDialog extends StatefulWidget {
  final String? patientId;
  final InventoryItem item;

  const _PatientMaterialChargeDialog({
    this.patientId,
    required this.item,
  });

  @override
  State<_PatientMaterialChargeDialog> createState() =>
      _PatientMaterialChargeDialogState();
}

class _PatientMaterialChargeDialogState extends State<_PatientMaterialChargeDialog> {
  String? _patientId;
  Future<List<ClinicalEncounterChargeOption>>? _encountersFuture;
  String? _encounterId;
  final _quantityCtrl = TextEditingController(text: '1');
  final _unitPriceCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _patientId = widget.patientId;
    _reloadEncounters();
  }

  void _reloadEncounters() {
    final pid = _patientId?.trim();
    if (pid == null || pid.isEmpty) {
      _encountersFuture = Future.value(const []);
      return;
    }
    _encountersFuture =
        ClinicalEncounterMaterialChargeDataSource.listForPatient(pid);
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _unitPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_patientId == null || _patientId!.isEmpty) {
      showClinicalSnackBar(context, 'Hasta seçin.', isError: true);
      return;
    }
    if (_encounterId == null || _encounterId!.isEmpty) {
      showClinicalSnackBar(context, 'Muayene seçin.', isError: true);
      return;
    }

    final qty = double.tryParse(_quantityCtrl.text.replaceAll(',', '.'));
    final price = double.tryParse(_unitPriceCtrl.text.replaceAll(',', '.'));
    if (qty == null || qty <= 0) {
      showClinicalSnackBar(context, 'Geçerli miktar girin.', isError: true);
      return;
    }
    if (price == null || price < 0) {
      showClinicalSnackBar(context, 'Geçerli birim fiyat girin.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final encounters = await (_encountersFuture ?? Future.value(const []));
    final encounter = encounters.firstWhere((e) => e.id == _encounterId);

    final result = await PatientMaterialChargeOrchestrator.charge(
      encounter: encounter,
      item: widget.item,
      quantity: qty,
      unitPrice: price,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.hasError) {
      showClinicalSnackBar(context, result.errorMessage!, isError: true);
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Hastaya malzeme şarjı — ${widget.item.name}'),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<List<ClinicalEncounterChargeOption>>(
          future: _encountersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final encounters = snapshot.data ?? const [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.patientId == null) ...[
                  PatientSelectorField(
                    selectedPatientId: _patientId,
                    labelText: 'Hasta seçin',
                    isDense: true,
                    onChanged: (v) => setState(() {
                      _patientId = v;
                      _encounterId = null;
                      _reloadEncounters();
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
                if (encounters.isEmpty)
                  ClinicalNotice(
                    tone: ClinicalNoticeTone.warning,
                    dense: true,
                    message:
                        'Bu hasta için şarj edilebilecek muayene kaydı bulunamadı.',
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _encounterId,
                    decoration: const InputDecoration(
                      labelText: 'Muayene seçin',
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: encounters
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(
                              e.displayLabel,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _encounterId = v),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityCtrl,
                  decoration: InputDecoration(
                    labelText: 'Miktar (${widget.item.unit})',
                    isDense: true,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unitPriceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Birim fiyat (TL)',
                    isDense: true,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Şarj et'),
        ),
      ],
    );
  }
}
