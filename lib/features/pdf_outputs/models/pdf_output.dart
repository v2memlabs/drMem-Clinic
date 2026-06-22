enum DocumentType {
  muayeneOzeti,
  goruntulemeOzeti,
  tedaviPlani,
  egzersizProgrami,
  postOpProtokol,
  ameliyatGirisimNotu,
  ameliyatSonrasi,
  enjeksiyonSonrasi,
  fizyoterapiYonlendirme,
  kontrolPlani,
  hastaBilgilendirmeFormu,
  onamFormu,
}

enum PdfStatus { taslak, hazirlandi, hastayaVerildi, gonderildi, iptal }

/// PdfOutput kaynak modülü: [ClinicalEncounter] muayene özeti hazırlama.
const String pdfSourceModuleClinicalEncounter = 'clinical_encounter';

/// PdfOutput kaynak modülü: onam şablonundan belge hazırlama.
const String pdfSourceModuleConsentTemplate = 'consent_template';

/// PdfOutput kaynak modülü: post-op protokol.
const String pdfSourceModulePostOpProtocol = 'post_op_protocol';

/// PdfOutput kaynak modülü: egzersiz programı.
const String pdfSourceModuleExercisePlan = 'exercise_plan';

/// PdfOutput kaynak modülü: ameliyat / girişim notu.
const String pdfSourceModuleSurgeryNote = 'surgery_note';

/// PdfOutput kaynak modülü: görüntüleme notu.
const String pdfSourceModuleImagingNote = 'imaging_note';

/// PdfOutput kaynak modülü: fizyoterapi yönlendirmesi.
const String pdfSourceModulePhysiotherapyReferral = 'physiotherapy_referral';

/// PdfOutput kaynak modülü: randevu.
const String pdfSourceModuleAppointment = 'appointment';

class PdfOutput {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime createdAt;
  final DocumentType documentType;
  final String title;
  final String? relatedDiagnosis;
  final String? relatedTreatmentPlan;
  final String contentSummary;
  final String warningNote;
  final String createdBy;
  final PdfStatus status;
  final String? sourceModule;
  final String? sourceRecordId;
  final String? storageBucket;
  final String? storagePath;

  PdfOutput({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.createdAt,
    required this.documentType,
    required this.title,
    this.relatedDiagnosis,
    this.relatedTreatmentPlan,
    required this.contentSummary,
    required this.warningNote,
    required this.createdBy,
    required this.status,
    this.sourceModule,
    this.sourceRecordId,
    this.storageBucket,
    this.storagePath,
  });
}

String pdfSourceModuleLabel(String? module) {
  switch (module) {
    case pdfSourceModuleClinicalEncounter:
      return 'Muayene Kayıtları';
    case pdfSourceModuleConsentTemplate:
      return 'Onam Şablonu';
    case pdfSourceModulePostOpProtocol:
      return 'Post-op Protokol';
    case pdfSourceModuleExercisePlan:
      return 'Egzersiz Programı';
    case pdfSourceModuleSurgeryNote:
      return 'Ameliyat / Girişim Notu';
    case pdfSourceModuleImagingNote:
      return 'Görüntüleme Notu';
    case pdfSourceModulePhysiotherapyReferral:
      return 'Fizyoterapi Yönlendirme';
    case pdfSourceModuleAppointment:
      return 'Randevu';
    default:
      return 'Kaynak belge';
  }
}

String documentTypeLabel(DocumentType type) {
  switch (type) {
    case DocumentType.muayeneOzeti:
      return 'Muayene Özeti';
    case DocumentType.goruntulemeOzeti:
      return 'Görüntüleme Özeti';
    case DocumentType.tedaviPlani:
      return 'Tedavi Planı';
    case DocumentType.egzersizProgrami:
      return 'Egzersiz Programı';
    case DocumentType.postOpProtokol:
      return 'Post-op Protokol';
    case DocumentType.ameliyatGirisimNotu:
      return 'Ameliyat / Girişim Notu';
    case DocumentType.ameliyatSonrasi:
      return 'Ameliyat Sonrası';
    case DocumentType.enjeksiyonSonrasi:
      return 'Enjeksiyon Sonrası';
    case DocumentType.fizyoterapiYonlendirme:
      return 'Fizyoterapi Yönlendirme Formu';
    case DocumentType.kontrolPlani:
      return 'Kontrol Planı';
    case DocumentType.hastaBilgilendirmeFormu:
      return 'Hasta Bilgilendirme Formu';
    case DocumentType.onamFormu:
      return 'Onam Formu';
  }
}

String pdfStatusLabel(PdfStatus status) {
  switch (status) {
    case PdfStatus.taslak:
      return 'Taslak';
    case PdfStatus.hazirlandi:
      return 'Hazırlandı';
    case PdfStatus.hastayaVerildi:
      return 'Hastaya Verildi';
    case PdfStatus.gonderildi:
      return 'Gönderildi';
    case PdfStatus.iptal:
      return 'İptal';
  }
}
