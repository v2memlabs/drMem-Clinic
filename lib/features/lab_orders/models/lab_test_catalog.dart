/// Laboratuvar isteminde seçilebilir tahlil / değerlendirme kodları.
enum LabTestCode {
  hemogram,
  biyokimyaTam,
  biyokimyaGlukoz,
  biyokimyaUre,
  biyokimyaKreatinin,
  biyokimyaAst,
  biyokimyaAlt,
  biyokimyaSodyum,
  biyokimyaPotasyum,
  biyokimyaCpk,
  ptaInr,
  elisa,
  elisaHbsag,
  elisaAntiHcv,
  elisaAntiHiv,
  kanGazi,
  kanGrubu,
  crp,
  sedim,
  prokalsitonin,
  kanKulturu,
  idrarKulturu,
  eklemPunktiyonKulturu,
  gramBoyama,
  idrarTahlili,
  tiroidFonksiyon,
  vitaminD,
  ekg,
  eforEkg,
  ritimHolter,
  akcigerGrafisi,
}

enum LabTestGroup { preoperatif, enfeksiyon, ekgDegerlendirme, diger }

enum InfectionContext { yok, septikArtrit, sellulit, osteomiyelit, endokardit, diger }

/// Biyokimya tam panel altındaki tek tek tahliller.
const List<LabTestCode> labBiochemistryComponentCodes = [
  LabTestCode.biyokimyaGlukoz,
  LabTestCode.biyokimyaUre,
  LabTestCode.biyokimyaKreatinin,
  LabTestCode.biyokimyaAst,
  LabTestCode.biyokimyaAlt,
  LabTestCode.biyokimyaSodyum,
  LabTestCode.biyokimyaPotasyum,
  LabTestCode.biyokimyaCpk,
];

const LabTestCode labBiochemistryPanelCode = LabTestCode.biyokimyaTam;

/// ELISA tam panel altındaki tek tek testler.
const List<LabTestCode> labElisaComponentCodes = [
  LabTestCode.elisaHbsag,
  LabTestCode.elisaAntiHcv,
  LabTestCode.elisaAntiHiv,
];

const LabTestCode labElisaPanelCode = LabTestCode.elisa;

bool isLabBiochemistryComponent(LabTestCode code) =>
    labBiochemistryComponentCodes.contains(code);

bool isLabBiochemistryPanelOrComponent(LabTestCode code) =>
    code == labBiochemistryPanelCode || isLabBiochemistryComponent(code);

bool isLabElisaComponent(LabTestCode code) =>
    labElisaComponentCodes.contains(code);

bool isLabElisaPanelOrComponent(LabTestCode code) =>
    code == labElisaPanelCode || isLabElisaComponent(code);

String labTestCodeLabel(LabTestCode code) {
  switch (code) {
    case LabTestCode.hemogram:
      return 'Hemogram';
    case LabTestCode.biyokimyaTam:
      return 'Biyokimya (tam panel)';
    case LabTestCode.biyokimyaGlukoz:
      return 'Glukoz';
    case LabTestCode.biyokimyaUre:
      return 'Üre';
    case LabTestCode.biyokimyaKreatinin:
      return 'Kreatinin';
    case LabTestCode.biyokimyaAst:
      return 'AST (SGOT)';
    case LabTestCode.biyokimyaAlt:
      return 'ALT (SGPT)';
    case LabTestCode.biyokimyaSodyum:
      return 'Sodyum';
    case LabTestCode.biyokimyaPotasyum:
      return 'Potasyum';
    case LabTestCode.biyokimyaCpk:
      return 'CPK (CK)';
    case LabTestCode.ptaInr:
      return 'PT/a-INR';
    case LabTestCode.elisa:
      return 'ELISA (tam panel)';
    case LabTestCode.elisaHbsag:
      return 'HBsAg';
    case LabTestCode.elisaAntiHcv:
      return 'Anti-HCV';
    case LabTestCode.elisaAntiHiv:
      return 'Anti-HIV';
    case LabTestCode.kanGazi:
      return 'Kan gazı';
    case LabTestCode.kanGrubu:
      return 'Kan grubu / cross-match';
    case LabTestCode.crp:
      return 'CRP';
    case LabTestCode.sedim:
      return 'Sedim';
    case LabTestCode.prokalsitonin:
      return 'Prokalsitonin';
    case LabTestCode.kanKulturu:
      return 'Kan kültürü';
    case LabTestCode.idrarKulturu:
      return 'İdrar kültürü';
    case LabTestCode.eklemPunktiyonKulturu:
      return 'Eklem ponksiyon kültürü + antibiyogram';
    case LabTestCode.gramBoyama:
      return 'Gram boyama';
    case LabTestCode.idrarTahlili:
      return 'İdrar tahlili';
    case LabTestCode.tiroidFonksiyon:
      return 'Tiroid fonksiyon';
    case LabTestCode.vitaminD:
      return 'Vitamin D';
    case LabTestCode.ekg:
      return 'EKG';
    case LabTestCode.eforEkg:
      return 'Efor EKG';
    case LabTestCode.ritimHolter:
      return 'Ritim Holter';
    case LabTestCode.akcigerGrafisi:
      return 'Akciğer grafisi';
  }
}

String labTestGroupLabel(LabTestGroup group) {
  switch (group) {
    case LabTestGroup.preoperatif:
      return 'Preoperatif laboratuvar';
    case LabTestGroup.enfeksiyon:
      return 'Enfeksiyon şüphesi';
    case LabTestGroup.ekgDegerlendirme:
      return 'EKG / ek değerlendirme';
    case LabTestGroup.diger:
      return 'Diğer';
  }
}

String infectionContextLabel(InfectionContext context) {
  switch (context) {
    case InfectionContext.yok:
      return 'Yok';
    case InfectionContext.septikArtrit:
      return 'Septik artrit';
    case InfectionContext.sellulit:
      return 'Sellülit';
    case InfectionContext.osteomiyelit:
      return 'Osteomiyelit';
    case InfectionContext.endokardit:
      return 'Endokardit';
    case InfectionContext.diger:
      return 'Diğer enfeksiyon';
  }
}

LabTestGroup labTestGroupFor(LabTestCode code) {
  if (isLabBiochemistryComponent(code) || code == labBiochemistryPanelCode) {
    return LabTestGroup.preoperatif;
  }
  if (isLabElisaComponent(code) || code == labElisaPanelCode) {
    return LabTestGroup.preoperatif;
  }
  switch (code) {
    case LabTestCode.hemogram:
    case LabTestCode.ptaInr:
    case LabTestCode.kanGrubu:
      return LabTestGroup.preoperatif;
    case LabTestCode.crp:
    case LabTestCode.sedim:
    case LabTestCode.prokalsitonin:
    case LabTestCode.kanKulturu:
    case LabTestCode.idrarKulturu:
    case LabTestCode.eklemPunktiyonKulturu:
    case LabTestCode.gramBoyama:
      return LabTestGroup.enfeksiyon;
    case LabTestCode.ekg:
    case LabTestCode.eforEkg:
    case LabTestCode.ritimHolter:
      return LabTestGroup.ekgDegerlendirme;
    case LabTestCode.kanGazi:
    case LabTestCode.idrarTahlili:
    case LabTestCode.tiroidFonksiyon:
    case LabTestCode.vitaminD:
    case LabTestCode.akcigerGrafisi:
      return LabTestGroup.diger;
    case LabTestCode.biyokimyaTam:
    case LabTestCode.biyokimyaGlukoz:
    case LabTestCode.biyokimyaUre:
    case LabTestCode.biyokimyaKreatinin:
    case LabTestCode.biyokimyaAst:
    case LabTestCode.biyokimyaAlt:
    case LabTestCode.biyokimyaSodyum:
    case LabTestCode.biyokimyaPotasyum:
    case LabTestCode.biyokimyaCpk:
    case LabTestCode.elisa:
    case LabTestCode.elisaHbsag:
    case LabTestCode.elisaAntiHcv:
    case LabTestCode.elisaAntiHiv:
      return LabTestGroup.preoperatif;
  }
}

/// Varsayılan «Diğer» grubu tahlilleri — tenant ayarı ile kısıtlanabilir.
const List<LabTestCode> labDefaultDigerTestCodes = [
  LabTestCode.kanGazi,
  LabTestCode.idrarTahlili,
  LabTestCode.tiroidFonksiyon,
  LabTestCode.vitaminD,
  LabTestCode.akcigerGrafisi,
];

List<LabTestCode> labTestsInGroup(LabTestGroup group) {
  return LabTestCode.values
      .where((code) => labTestGroupFor(code) == group)
      .toList();
}

/// Preoperatif grubunda biyokimya bileşenleri hariç (ayrı alt bölümde gösterilir).
List<LabTestCode> labPreoperatifTestsOutsideBiochemistry() {
  return labTestsInGroup(LabTestGroup.preoperatif)
      .where(
        (code) =>
            code != labBiochemistryPanelCode &&
            !isLabBiochemistryComponent(code) &&
            code != labElisaPanelCode &&
            !isLabElisaComponent(code),
      )
      .toList();
}
