import '../models/lab_test_catalog.dart';



/// Biyokimya / ELISA tam panel ↔ tek tek seçim senkronizasyonu.

abstract final class LabTestSelection {

  static bool isBiochemistryPanelChecked(Set<LabTestCode> selected) {

    if (selected.contains(labBiochemistryPanelCode)) return true;

    return labBiochemistryComponentCodes.every(selected.contains);

  }



  static bool isElisaPanelChecked(Set<LabTestCode> selected) {

    if (selected.contains(labElisaPanelCode)) return true;

    return labElisaComponentCodes.every(selected.contains);

  }



  static void setBiochemistryPanel(Set<LabTestCode> selected, bool checked) {

    if (checked) {

      selected.add(labBiochemistryPanelCode);

      selected.addAll(labBiochemistryComponentCodes);

    } else {

      selected.remove(labBiochemistryPanelCode);

      selected.removeAll(labBiochemistryComponentCodes);

    }

  }



  static void setElisaPanel(Set<LabTestCode> selected, bool checked) {

    if (checked) {

      selected.add(labElisaPanelCode);

      selected.addAll(labElisaComponentCodes);

    } else {

      selected.remove(labElisaPanelCode);

      selected.removeAll(labElisaComponentCodes);

    }

  }



  static void toggleTest(Set<LabTestCode> selected, LabTestCode code, bool checked) {

    if (checked) {

      selected.add(code);

    } else {

      selected.remove(code);

    }

    if (isLabBiochemistryComponent(code) || code == labBiochemistryPanelCode) {

      _syncBiochemistryPanelFlag(selected);

    }

    if (isLabElisaComponent(code) || code == labElisaPanelCode) {

      _syncElisaPanelFlag(selected);

    }

  }



  static void _syncBiochemistryPanelFlag(Set<LabTestCode> selected) {

    if (labBiochemistryComponentCodes.every(selected.contains)) {

      selected.add(labBiochemistryPanelCode);

    } else {

      selected.remove(labBiochemistryPanelCode);

    }

  }



  static void _syncElisaPanelFlag(Set<LabTestCode> selected) {

    if (labElisaComponentCodes.every(selected.contains)) {

      selected.add(labElisaPanelCode);

    } else {

      selected.remove(labElisaPanelCode);

    }

  }



  /// Kayıt: tam panel seçiliyse yalnızca panel kodu saklanır.

  static List<LabTestCode> normalizeForStorage(Iterable<LabTestCode> tests) {

    final set = tests.toSet();

    if (labBiochemistryComponentCodes.every(set.contains)) {

      set.removeAll(labBiochemistryComponentCodes);

      set.add(labBiochemistryPanelCode);

    }

    if (labElisaComponentCodes.every(set.contains)) {

      set.removeAll(labElisaComponentCodes);

      set.add(labElisaPanelCode);

    }

    return LabTestCode.values.where(set.contains).toList();

  }



  /// Form düzenleme: tam panel kodunu bileşenlere açar.

  static Set<LabTestCode> expandForEditing(Iterable<LabTestCode> tests) {

    final set = tests.toSet();

    if (set.contains(labBiochemistryPanelCode)) {

      set.addAll(labBiochemistryComponentCodes);

    }

    if (set.contains(labElisaPanelCode)) {

      set.addAll(labElisaComponentCodes);

    }

    return set;

  }



  /// PDF: tam panel tek madde; kısmi seçimde bileşenler ayrı listelenir.

  static List<LabTestCode> codesForPdfGroup(

    LabTestGroup group,

    Iterable<LabTestCode> tests,

  ) {

    final set = tests.toSet();

    final inGroup = set.where((c) => labTestGroupFor(c) == group).toList();

    if (group != LabTestGroup.preoperatif) return inGroup;



    final hasFullBiochemistry = set.contains(labBiochemistryPanelCode) ||

        labBiochemistryComponentCodes.every(set.contains);

    final hasFullElisa = set.contains(labElisaPanelCode) ||

        labElisaComponentCodes.every(set.contains);



    final withoutPanelsAndComponents = inGroup

        .where((c) => !isLabBiochemistryComponent(c))

        .where((c) => c != labBiochemistryPanelCode)

        .where((c) => !isLabElisaComponent(c))

        .where((c) => c != labElisaPanelCode)

        .toList();



    final result = <LabTestCode>[];



    if (hasFullBiochemistry) {

      result.add(labBiochemistryPanelCode);

    } else {

      result.addAll(inGroup.where(isLabBiochemistryComponent));

    }



    if (hasFullElisa) {

      result.add(labElisaPanelCode);

    } else {

      result.addAll(inGroup.where(isLabElisaComponent));

    }



    result.addAll(withoutPanelsAndComponents);

    return result;

  }

}


