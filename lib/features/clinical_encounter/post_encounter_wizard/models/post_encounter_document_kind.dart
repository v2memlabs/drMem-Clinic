/// Muayene sonrası sihirbazında oluşturulabilecek belge türleri.
enum PostEncounterDocumentKind {
  lab,
  radiology,
  prescription,
  clinicalReport,
}

extension PostEncounterDocumentKindLabels on PostEncounterDocumentKind {
  String get label {
    switch (this) {
      case PostEncounterDocumentKind.lab:
        return 'Laboratuvar';
      case PostEncounterDocumentKind.radiology:
        return 'Görüntüleme';
      case PostEncounterDocumentKind.prescription:
        return 'Reçete';
      case PostEncounterDocumentKind.clinicalReport:
        return 'Rapor';
    }
  }
}
