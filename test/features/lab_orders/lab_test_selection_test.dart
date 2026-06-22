import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/lab_orders/data/lab_test_selection.dart';
import 'package:v2mem_clinic/features/lab_orders/models/lab_test_catalog.dart';

void main() {
  test('biochemistry panel selects all components', () {
    final selected = <LabTestCode>{};
    LabTestSelection.setBiochemistryPanel(selected, true);
    expect(selected.contains(labBiochemistryPanelCode), isTrue);
    expect(
      labBiochemistryComponentCodes.every(selected.contains),
      isTrue,
    );
  });

  test('normalize stores tam panel when all components selected', () {
    final selected = <LabTestCode>{
      LabTestCode.hemogram,
      ...labBiochemistryComponentCodes,
    };
    final normalized = LabTestSelection.normalizeForStorage(selected);
    expect(normalized.contains(labBiochemistryPanelCode), isTrue);
    expect(
      labBiochemistryComponentCodes.any(normalized.contains),
      isFalse,
    );
  });

  test('pdf group collapses full biochemistry panel', () {
    final codes = LabTestSelection.codesForPdfGroup(
      LabTestGroup.preoperatif,
      [labBiochemistryPanelCode, LabTestCode.hemogram],
    );
    expect(codes, [labBiochemistryPanelCode, LabTestCode.hemogram]);
  });

  test('pdf group lists partial biochemistry components', () {
    final codes = LabTestSelection.codesForPdfGroup(
      LabTestGroup.preoperatif,
      [LabTestCode.biyokimyaGlukoz, LabTestCode.biyokimyaUre],
    );
    expect(codes, contains(LabTestCode.biyokimyaGlukoz));
    expect(codes, isNot(contains(labBiochemistryPanelCode)));
  });

  test('elisa panel selects all components', () {
    final selected = <LabTestCode>{};
    LabTestSelection.setElisaPanel(selected, true);
    expect(selected.contains(labElisaPanelCode), isTrue);
    expect(labElisaComponentCodes.every(selected.contains), isTrue);
  });

  test('expand elisa panel for editing', () {
    final expanded = LabTestSelection.expandForEditing([labElisaPanelCode]);
    expect(labElisaComponentCodes.every(expanded.contains), isTrue);
  });

  test('pdf group collapses full elisa panel', () {
    final codes = LabTestSelection.codesForPdfGroup(
      LabTestGroup.preoperatif,
      [labElisaPanelCode, LabTestCode.hemogram],
    );
    expect(codes, [labElisaPanelCode, LabTestCode.hemogram]);
  });
}
