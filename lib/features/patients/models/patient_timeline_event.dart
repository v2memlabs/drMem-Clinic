enum TimelineEventType {
  randevu,
  anamnez,
  muayeneNotu,
  goruntuleme,
  tani,
  tedaviPlani,
  dosya,
  pdfCikti,
  odeme,
  mesaj,
  fizyoterapiYonlendirme,
  fizyoterapiSeansi,
  egzersizProgrami,
  ameliyatGirisim,
  postOpProtokol,
  kvkkOnam,
  auditLog,
}

class PatientTimelineEvent {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime eventDate;
  final TimelineEventType eventType;
  final String title;
  final String description;
  final String relatedModule;
  final String? relatedRecordId;
  final String? relatedRoute;
  final String createdBy;

  const PatientTimelineEvent({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.eventDate,
    required this.eventType,
    required this.title,
    required this.description,
    required this.relatedModule,
    this.relatedRecordId,
    this.relatedRoute,
    required this.createdBy,
  });
}

/// Timeline Faz 1 — klinik omurga olay tipleri.
const List<TimelineEventType> timelinePhase1EventTypes = [
  TimelineEventType.muayeneNotu,
  TimelineEventType.randevu,
  TimelineEventType.goruntuleme,
  TimelineEventType.ameliyatGirisim,
  TimelineEventType.postOpProtokol,
];

/// Timeline Faz 2 — takip ve operasyonel olay tipleri.
const List<TimelineEventType> timelinePhase2EventTypes = [
  TimelineEventType.fizyoterapiYonlendirme,
  TimelineEventType.fizyoterapiSeansi,
  TimelineEventType.egzersizProgrami,
  TimelineEventType.dosya,
  TimelineEventType.kvkkOnam,
];

/// Timeline Faz 3 — finans, iletişim ve PDF olay tipleri.
const List<TimelineEventType> timelinePhase3EventTypes = [
  TimelineEventType.odeme,
  TimelineEventType.mesaj,
  TimelineEventType.pdfCikti,
];

/// Timeline Faz 4 — audit log olay tipi.
const List<TimelineEventType> timelinePhase4EventTypes = [
  TimelineEventType.auditLog,
];

/// Builder’dan üretilen tüm aktif timeline olay tipleri (Faz 1–4).
const List<TimelineEventType> timelineRepositoryEventTypes = [
  ...timelinePhase1EventTypes,
  ...timelinePhase2EventTypes,
  ...timelinePhase3EventTypes,
  ...timelinePhase4EventTypes,
];

String timelineEventTypeLabel(TimelineEventType type) {
  switch (type) {
    case TimelineEventType.randevu:
      return 'Randevu';
    case TimelineEventType.anamnez:
      return 'Anamnez';
    case TimelineEventType.muayeneNotu:
      return 'Muayene Kaydı';
    case TimelineEventType.goruntuleme:
      return 'Görüntüleme';
    case TimelineEventType.tani:
      return 'Tanı';
    case TimelineEventType.tedaviPlani:
      return 'Tedavi Planı';
    case TimelineEventType.dosya:
      return 'Dosya';
    case TimelineEventType.pdfCikti:
      return 'PDF Çıktı';
    case TimelineEventType.odeme:
      return 'Ödeme';
    case TimelineEventType.mesaj:
      return 'Mesaj';
    case TimelineEventType.fizyoterapiYonlendirme:
      return 'Fizyoterapi Yönlendirmesi';
    case TimelineEventType.fizyoterapiSeansi:
      return 'Fizyoterapi Seansı';
    case TimelineEventType.egzersizProgrami:
      return 'Egzersiz Programı';
    case TimelineEventType.ameliyatGirisim:
      return 'Ameliyat / Girişim';
    case TimelineEventType.postOpProtokol:
      return 'Post-op Protokol';
    case TimelineEventType.kvkkOnam:
      return 'KVKK / Onam';
    case TimelineEventType.auditLog:
      return 'İşlem Kaydı';
  }
}
