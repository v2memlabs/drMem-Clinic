enum ImagingType { mr, bt, direktGrafi, usg, rapor, diger }

enum ImagingBodyRegion {
  diz,
  omuz,
  kalca,
  ayakBilegi,
  ayak,
  dirsek,
  elBilegi,
  el,
  omurga,
  diger
}

enum ImagingSide { sag, sol, bilateral, uygunDegil }

class ImagingNote {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime createdAt;
  final ImagingType imagingType;
  final DateTime imagingDate;
  final String imagingCenter;
  final ImagingBodyRegion bodyRegion;
  final ImagingSide side;
  final String reportSummary;
  final String doctorComment;
  final String comparisonWithPrevious;
  final String relatedDiagnosis;
  final String? relatedVisitDate;
  final String? attachedFileName;

  ImagingNote({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.createdAt,
    required this.imagingType,
    required this.imagingDate,
    required this.imagingCenter,
    required this.bodyRegion,
    required this.side,
    required this.reportSummary,
    required this.doctorComment,
    required this.comparisonWithPrevious,
    required this.relatedDiagnosis,
    this.relatedVisitDate,
    this.attachedFileName,
  });
}

String imagingSideLabel(ImagingSide side) {
  switch (side) {
    case ImagingSide.sag:
      return 'Sağ';
    case ImagingSide.sol:
      return 'Sol';
    case ImagingSide.bilateral:
      return 'Bilateral';
    case ImagingSide.uygunDegil:
      return 'Uygun Değil';
  }
}
