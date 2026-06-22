import 'package:flutter/material.dart';

import '../../../shared/widgets/form_section_card.dart';
import '../data/lab_order_catalog_gate.dart';
import '../data/lab_test_selection.dart';
import '../models/lab_test_catalog.dart';

/// Laboratuvar istem / şablon formlarında ortak tahlil seçici.
class LabTestSelector extends StatelessWidget {
  final Set<LabTestCode> selectedTests;
  final Set<String> selectedCustomTestIds;
  final ValueChanged<Set<LabTestCode>> onTestsChanged;
  final ValueChanged<Set<String>>? onCustomTestsChanged;

  const LabTestSelector({
    super.key,
    required this.selectedTests,
    this.selectedCustomTestIds = const {},
    required this.onTestsChanged,
    this.onCustomTestsChanged,
  });

  void _updateTests(Set<LabTestCode> next) {
    onTestsChanged(next);
  }

  void _toggle(LabTestCode code, bool? checked) {
    final next = Set<LabTestCode>.from(selectedTests);
    LabTestSelection.toggleTest(next, code, checked == true);
    _updateTests(next);
  }

  void _togglePanel(bool? checked) {
    final next = Set<LabTestCode>.from(selectedTests);
    LabTestSelection.setBiochemistryPanel(next, checked == true);
    _updateTests(next);
  }

  void _toggleCustom(String id, bool? checked) {
    if (onCustomTestsChanged == null) return;
    final next = Set<String>.from(selectedCustomTestIds);
    if (checked == true) {
      next.add(id);
    } else {
      next.remove(id);
    }
    onCustomTestsChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = LabOrderCatalogGate.current;
    final panelChecked = LabTestSelection.isBiochemistryPanelChecked(selectedTests);
    final elisaPanelChecked = LabTestSelection.isElisaPanelChecked(selectedTests);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionCard(
          title: labTestGroupLabel(LabTestGroup.preoperatif),
          icon: Icons.checklist_outlined,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labTestCodeLabel(labBiochemistryPanelCode)),
              subtitle: const Text('Tüm biyokimya bileşenlerini seçer'),
              value: panelChecked,
              onChanged: _togglePanel,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  for (final code in labBiochemistryComponentCodes)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(labTestCodeLabel(code)),
                      value: selectedTests.contains(code),
                      onChanged: (v) => _toggle(code, v),
                    ),
                ],
              ),
            ),
            const Divider(height: 20),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labTestCodeLabel(labElisaPanelCode)),
              subtitle: const Text('HBsAg, Anti-HCV, Anti-HIV'),
              value: elisaPanelChecked,
              onChanged: (v) {
                final next = Set<LabTestCode>.from(selectedTests);
                LabTestSelection.setElisaPanel(next, v == true);
                _updateTests(next);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  for (final code in labElisaComponentCodes)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(labTestCodeLabel(code)),
                      value: selectedTests.contains(code),
                      onChanged: (v) => _toggle(code, v),
                    ),
                ],
              ),
            ),
            const Divider(height: 20),
            for (final code in labPreoperatifTestsOutsideBiochemistry())
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(labTestCodeLabel(code)),
                value: selectedTests.contains(code),
                onChanged: (v) => _toggle(code, v),
              ),
          ],
        ),
        for (final group in [
          LabTestGroup.enfeksiyon,
          LabTestGroup.ekgDegerlendirme,
        ])
          FormSectionCard(
            title: labTestGroupLabel(group),
            icon: Icons.checklist_outlined,
            children: [
              for (final code in labTestsInGroup(group))
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(labTestCodeLabel(code)),
                  value: selectedTests.contains(code),
                  onChanged: (v) => _toggle(code, v),
                ),
            ],
          ),
        FormSectionCard(
          title: labTestGroupLabel(LabTestGroup.diger),
          icon: Icons.checklist_outlined,
          children: [
            if (catalog.visibleDigerBuiltInTests.isEmpty &&
                catalog.customTests.isEmpty)
              const Text('Diğer test listesi boş. Şablonlar ekranından düzenleyin.'),
            for (final code in catalog.visibleDigerBuiltInTests)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(labTestCodeLabel(code)),
                value: selectedTests.contains(code),
                onChanged: (v) => _toggle(code, v),
              ),
            if (onCustomTestsChanged != null)
              for (final entry in catalog.customTests)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.label),
                  value: selectedCustomTestIds.contains(entry.id),
                  onChanged: (v) => _toggleCustom(entry.id, v),
                ),
          ],
        ),
      ],
    );
  }
}
