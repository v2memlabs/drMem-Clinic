enum ProcedureType {
  ameliyat,
  artroskopi,
  enjeksiyonGirisim,
  yaraPansuman,
  kontrolAmacli,
  diger,
}

enum SurgeryBodyRegion {
  diz,
  omuz,
  kalca,
  ayakBilegi,
  ayak,
  dirsek,
  elBilegi,
  el,
  omurga,
  diger,
}

enum SurgerySide {
  sag,
  sol,
  bilateral,
  uygunDegil,
}

class SurgeryProcedureNote {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime procedureDate;
  final ProcedureType procedureType;
  final SurgeryBodyRegion bodyRegion;
  final SurgerySide side;
  final String diagnosis;
  final String procedureName;
  final String anesthesiaType;
  final String asaScore;
  final bool? tourniquetUsed;
  final String implantOrMaterialInfo;
  final String arthroscopyFindings;
  final String procedureDetails;
  final String complications;
  final String postOpRecommendations;
  final String physiotherapyStartRecommendation;
  final String controlSchedule;
  final String surgeonName;
  final String assistantInfo;
  final String notes;
  final String? createdByProfileId;

  const SurgeryProcedureNote({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.procedureDate,
    required this.procedureType,
    required this.bodyRegion,
    required this.side,
    required this.diagnosis,
    required this.procedureName,
    required this.anesthesiaType,
    this.asaScore = '',
    this.tourniquetUsed,
    required this.implantOrMaterialInfo,
    required this.arthroscopyFindings,
    required this.procedureDetails,
    required this.complications,
    required this.postOpRecommendations,
    required this.physiotherapyStartRecommendation,
    required this.controlSchedule,
    required this.surgeonName,
    required this.assistantInfo,
    this.notes = '',
    this.createdByProfileId,
  });
}

bool procedureTypeUsesSurgeryNote(ProcedureType type) =>
    type == ProcedureType.ameliyat;

String procedureNoteFieldLabel(ProcedureType type) =>
    procedureTypeUsesSurgeryNote(type) ? 'Ameliyat Notu' : 'İşlem Detayları';

bool procedureTypeUsesAmeliyatNoteCardTitle(ProcedureType type) =>
    type == ProcedureType.ameliyat || type == ProcedureType.artroskopi;

String surgeryDetailNoteCardTitle(ProcedureType type) =>
    procedureTypeUsesAmeliyatNoteCardTitle(type)
        ? 'Ameliyat Notu'
        : 'Girişim Notu';

String tourniquetLabel(bool? used) {
  if (used == null) return 'Belirtilmedi';
  return used ? 'Var' : 'Yok';
}

List<String> decodeImplantMaterialLines(String raw) {
  return raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

String encodeImplantMaterialLines(Iterable<String> lines) {
  return lines
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
}

const List<String> asaScoreOptions = [
  'ASA I',
  'ASA II',
  'ASA III',
  'ASA IV',
  'ASA V',
  'ASA VI',
];

String procedureTypeLabel(ProcedureType type) {
  switch (type) {
    case ProcedureType.ameliyat:
      return 'Ameliyat';
    case ProcedureType.artroskopi:
      return 'Artroskopi';
    case ProcedureType.enjeksiyonGirisim:
      return 'Enjeksiyon / Girişim';
    case ProcedureType.yaraPansuman:
      return 'Yara / Pansuman Girişimi';
    case ProcedureType.kontrolAmacli:
      return 'Kontrol Amaçlı İşlem';
    case ProcedureType.diger:
      return 'Diğer';
  }
}

String surgeryBodyRegionLabel(SurgeryBodyRegion region) {
  switch (region) {
    case SurgeryBodyRegion.diz:
      return 'Diz';
    case SurgeryBodyRegion.omuz:
      return 'Omuz';
    case SurgeryBodyRegion.kalca:
      return 'Kalça';
    case SurgeryBodyRegion.ayakBilegi:
      return 'Ayak Bileği';
    case SurgeryBodyRegion.ayak:
      return 'Ayak';
    case SurgeryBodyRegion.dirsek:
      return 'Dirsek';
    case SurgeryBodyRegion.elBilegi:
      return 'El Bileği';
    case SurgeryBodyRegion.el:
      return 'El';
    case SurgeryBodyRegion.omurga:
      return 'Omurga';
    case SurgeryBodyRegion.diger:
      return 'Diğer';
  }
}

String surgerySideLabel(SurgerySide side) {
  switch (side) {
    case SurgerySide.sag:
      return 'Sağ';
    case SurgerySide.sol:
      return 'Sol';
    case SurgerySide.bilateral:
      return 'Bilateral';
    case SurgerySide.uygunDegil:
      return 'Uygun Değil';
  }
}
