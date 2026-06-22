enum ClinicalReportType {
  istirahat,
  durumBildirir,
  ucabilir,
  cihazKullanim,
  diger,
}

enum ClinicalReportStatus { taslak, hazirlandi, hastayaVerildi, iptal }

/// PDF'de gösterilecek tarih kaynağı.
enum ClinicalReportDocumentDateSource { belgeTarihi, muayeneTarihi }

/// İstirahat / durum bildirir — tedavi yaklaşımı.
enum ClinicalReportTreatmentApproach { konservatif, cerrahi }

/// Durum bildirir — öneri/kısıtlama uygunluk ifadesi.
enum ClinicalReportStatusSuitability { uygun, sakincali }

/// Uçabilir raporu — uçuş kararı.
enum ClinicalReportFlightDecision { ucabilir, ucamaz, kosullu }

/// Cihaz raporu — yük bindirme durumu.
enum ClinicalReportWeightBearing { tam, kismi, yukBindirmesiz }

class ClinicalReport {
  final String id;
  final String patientId;
  final String patientName;
  final String? clinicalEncounterId;
  /// Muayene protokol no — kayıt anında snapshot (ör. M-2026-00001).
  final String? clinicalEncounterProtocolNumber;
  /// Rapor belge no — kayıt anında atanır (ör. R-2026-00001).
  final String? reportNumber;
  final ClinicalReportDocumentDateSource documentDateSource;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final ClinicalReportStatus status;
  final ClinicalReportType reportType;
  final String diagnosis;
  final String bodyText;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? restDays;
  final ClinicalReportTreatmentApproach? treatmentApproach;
  final String? restrictionNotes;
  final String? statusDuration;
  final String? statusRecommendation;
  final ClinicalReportStatusSuitability? statusSuitability;
  final String? supplementaryNotes;
  final ClinicalReportFlightDecision? flightDecision;
  final String? deviceUsageDuration;
  final ClinicalReportWeightBearing? weightBearing;
  final String? deviceName;
  final String? deviceUsageNotes;
  final String? flightNotes;

  const ClinicalReport({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.clinicalEncounterId,
    this.clinicalEncounterProtocolNumber,
    this.reportNumber,
    this.documentDateSource = ClinicalReportDocumentDateSource.belgeTarihi,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    required this.status,
    required this.reportType,
    required this.diagnosis,
    required this.bodyText,
    this.startDate,
    this.endDate,
    this.restDays,
    this.treatmentApproach,
    this.restrictionNotes,
    this.statusDuration,
    this.statusRecommendation,
    this.statusSuitability,
    this.supplementaryNotes,
    this.flightDecision,
    this.deviceUsageDuration,
    this.weightBearing,
    this.deviceName,
    this.deviceUsageNotes,
    this.flightNotes,
  });

  ClinicalReport copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? clinicalEncounterId,
    String? clinicalEncounterProtocolNumber,
    String? reportNumber,
    ClinicalReportDocumentDateSource? documentDateSource,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    ClinicalReportStatus? status,
    ClinicalReportType? reportType,
    String? diagnosis,
    String? bodyText,
    DateTime? startDate,
    DateTime? endDate,
    int? restDays,
    ClinicalReportTreatmentApproach? treatmentApproach,
    String? restrictionNotes,
    String? statusDuration,
    String? statusRecommendation,
    ClinicalReportStatusSuitability? statusSuitability,
    String? supplementaryNotes,
    ClinicalReportFlightDecision? flightDecision,
    String? deviceUsageDuration,
    ClinicalReportWeightBearing? weightBearing,
    String? deviceName,
    String? deviceUsageNotes,
    String? flightNotes,
  }) {
    return ClinicalReport(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      clinicalEncounterId: clinicalEncounterId ?? this.clinicalEncounterId,
      clinicalEncounterProtocolNumber: clinicalEncounterProtocolNumber ??
          this.clinicalEncounterProtocolNumber,
      reportNumber: reportNumber ?? this.reportNumber,
      documentDateSource: documentDateSource ?? this.documentDateSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      reportType: reportType ?? this.reportType,
      diagnosis: diagnosis ?? this.diagnosis,
      bodyText: bodyText ?? this.bodyText,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      restDays: restDays ?? this.restDays,
      treatmentApproach: treatmentApproach ?? this.treatmentApproach,
      restrictionNotes: restrictionNotes ?? this.restrictionNotes,
      statusDuration: statusDuration ?? this.statusDuration,
      statusRecommendation:
          statusRecommendation ?? this.statusRecommendation,
      statusSuitability: statusSuitability ?? this.statusSuitability,
      supplementaryNotes: supplementaryNotes ?? this.supplementaryNotes,
      flightDecision: flightDecision ?? this.flightDecision,
      deviceUsageDuration: deviceUsageDuration ?? this.deviceUsageDuration,
      weightBearing: weightBearing ?? this.weightBearing,
      deviceName: deviceName ?? this.deviceName,
      deviceUsageNotes: deviceUsageNotes ?? this.deviceUsageNotes,
      flightNotes: flightNotes ?? this.flightNotes,
    );
  }

  String? get displayProtocolNumber {
    final value = clinicalEncounterProtocolNumber?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  String? get displayReportNumber {
    final value = reportNumber?.trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

String clinicalReportDocumentDateSourceLabel(
  ClinicalReportDocumentDateSource source,
) {
  switch (source) {
    case ClinicalReportDocumentDateSource.belgeTarihi:
      return 'Belge tarihi';
    case ClinicalReportDocumentDateSource.muayeneTarihi:
      return 'Muayene tarihi';
  }
}

String treatmentApproachLabel(ClinicalReportTreatmentApproach approach) {
  switch (approach) {
    case ClinicalReportTreatmentApproach.konservatif:
      return 'konservatif';
    case ClinicalReportTreatmentApproach.cerrahi:
      return 'cerrahi';
  }
}

String statusSuitabilityFormLabel(ClinicalReportStatusSuitability value) {
  switch (value) {
    case ClinicalReportStatusSuitability.uygun:
      return 'Uygundur';
    case ClinicalReportStatusSuitability.sakincali:
      return 'Sakıncalıdır';
  }
}

String statusSuitabilityPhrase(ClinicalReportStatusSuitability value) {
  switch (value) {
    case ClinicalReportStatusSuitability.uygun:
      return 'uygundur';
    case ClinicalReportStatusSuitability.sakincali:
      return 'sakıncalıdır';
  }
}

/// Tüm klinik rapor PDF'lerinde ortak hitap satırı.
const String clinicalReportPdfSalutation = 'İlgili Makama,';

String flightDecisionFormLabel(ClinicalReportFlightDecision value) {
  switch (value) {
    case ClinicalReportFlightDecision.ucabilir:
      return 'Uçabilir';
    case ClinicalReportFlightDecision.ucamaz:
      return 'Uçamaz';
    case ClinicalReportFlightDecision.kosullu:
      return 'Koşullu uçabilir';
  }
}

String flightDecisionPhrase(ClinicalReportFlightDecision value) {
  switch (value) {
    case ClinicalReportFlightDecision.ucabilir:
      return 'uçakla seyahat etmesinde sakınca yoktur.';
    case ClinicalReportFlightDecision.ucamaz:
      return 'Uçakla seyahat etmesi sakıncalıdır.';
    case ClinicalReportFlightDecision.kosullu:
      return 'aşağıda belirtilen koşullar sağlandığında uçakla seyahat '
          'etmesinde sakınca yoktur.';
  }
}

String weightBearingFormLabel(ClinicalReportWeightBearing value) {
  switch (value) {
    case ClinicalReportWeightBearing.tam:
      return 'Tam yük bindirme';
    case ClinicalReportWeightBearing.kismi:
      return 'Kısmi yük bindirme';
    case ClinicalReportWeightBearing.yukBindirmesiz:
      return 'Yük bindirmesiz';
  }
}

String clinicalReportTypeLabel(ClinicalReportType type) {
  switch (type) {
    case ClinicalReportType.istirahat:
      return 'İstirahat Raporu';
    case ClinicalReportType.durumBildirir:
      return 'Durum Bildirir Rapor';
    case ClinicalReportType.ucabilir:
      return 'Uçabilir Raporu';
    case ClinicalReportType.cihazKullanim:
      return 'Cihaz Kullanım Raporu';
    case ClinicalReportType.diger:
      return 'Tek Hekim Raporu';
  }
}

String clinicalReportStatusLabel(ClinicalReportStatus status) {
  switch (status) {
    case ClinicalReportStatus.taslak:
      return 'Taslak';
    case ClinicalReportStatus.hazirlandi:
      return 'Hazırlandı';
    case ClinicalReportStatus.hastayaVerildi:
      return 'Hastaya Verildi';
    case ClinicalReportStatus.iptal:
      return 'İptal';
  }
}
