enum PatientAlertType {
  kontrolTarihiYaklasiyor,
  kontrolGecikmis,
  eksikTedaviPlani,
  eksikOnam,
  odemeBekliyor,
  fizyoterapistNotuBekleniyor,
  doktorBildirimiGerekli,
  postOpKontrol,
  kirmiziBayrak,
  genelUyari,
}

enum AlertSeverity {
  dusuk,
  orta,
  yuksek,
  kritik,
}

class PatientAlert {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime createdAt;
  final PatientAlertType alertType;
  final AlertSeverity severity;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String relatedModule;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String createdBy;
  final String? actionRoute;

  const PatientAlert({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.createdAt,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.description,
    this.dueDate,
    required this.relatedModule,
    this.isResolved = false,
    this.resolvedAt,
    required this.createdBy,
    this.actionRoute,
  });
}

String patientAlertTypeLabel(PatientAlertType type) {
  switch (type) {
    case PatientAlertType.kontrolTarihiYaklasiyor:
      return 'Kontrol Tarihi Yaklaşıyor';
    case PatientAlertType.kontrolGecikmis:
      return 'Kontrol Gecikmiş';
    case PatientAlertType.eksikTedaviPlani:
      return 'Eksik Tedavi Planı';
    case PatientAlertType.eksikOnam:
      return 'Eksik Onam';
    case PatientAlertType.odemeBekliyor:
      return 'Ödeme Bekliyor';
    case PatientAlertType.fizyoterapistNotuBekleniyor:
      return 'Fizyoterapist Notu Bekleniyor';
    case PatientAlertType.doktorBildirimiGerekli:
      return 'Doktor Bildirimi Gerekli';
    case PatientAlertType.postOpKontrol:
      return 'Post-op Kontrol';
    case PatientAlertType.kirmiziBayrak:
      return 'Kırmızı Bayrak';
    case PatientAlertType.genelUyari:
      return 'Genel Uyarı';
  }
}

String alertSeverityLabel(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.dusuk:
      return 'Düşük';
    case AlertSeverity.orta:
      return 'Orta';
    case AlertSeverity.yuksek:
      return 'Yüksek';
    case AlertSeverity.kritik:
      return 'Kritik';
  }
}
