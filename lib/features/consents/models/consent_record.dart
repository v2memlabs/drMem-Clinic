import 'consent_signature_mode.dart';

enum ConsentType {
  kvkkAydinlatma,
  acikRiza,
  whatsappIzin,
  smsIzin,
  emailIzin,
  fizyoterapistPaylasim,
  fotoVideoIzin,
  ameliyatOnami,
}

enum ConsentStatus { bekliyor, alindi, reddedildi, iptalEdildi, suresiDoldu }

class ConsentRecord {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime createdAt;
  final ConsentType consentType;
  final ConsentStatus status;
  final DateTime? givenAt;
  final DateTime? expiresAt;
  final String? documentFileName;
  final String recordedBy;
  final String? notes;
  final String? templateId;
  final String? templateVersion;
  final String? pdfOutputId;
  final String? appointmentId;
  final String? encounterId;
  final ConsentSignatureMode signatureMode;
  final Map<String, Object?> metadata;

  ConsentRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.createdAt,
    required this.consentType,
    required this.status,
    this.givenAt,
    this.expiresAt,
    this.documentFileName,
    required this.recordedBy,
    this.notes,
    this.templateId,
    this.templateVersion,
    this.pdfOutputId,
    this.appointmentId,
    this.encounterId,
    this.signatureMode = ConsentSignatureMode.pending,
    this.metadata = const {},
  });
}

String consentTypeLabel(ConsentType type) {
  switch (type) {
    case ConsentType.kvkkAydinlatma:
      return 'KVKK Aydınlatma';
    case ConsentType.acikRiza:
      return 'Açık Rıza';
    case ConsentType.whatsappIzin:
      return 'WhatsApp İzni';
    case ConsentType.smsIzin:
      return 'SMS İzni';
    case ConsentType.emailIzin:
      return 'E-posta İzni';
    case ConsentType.fizyoterapistPaylasim:
      return 'Fizyoterapist Paylaşım';
    case ConsentType.fotoVideoIzin:
      return 'Foto/Video İzni';
    case ConsentType.ameliyatOnami:
      return 'Ameliyat Onamı';
  }
}

String consentStatusLabel(ConsentStatus status) {
  switch (status) {
    case ConsentStatus.bekliyor:
      return 'Bekliyor';
    case ConsentStatus.alindi:
      return 'Alındı';
    case ConsentStatus.reddedildi:
      return 'Reddedildi';
    case ConsentStatus.iptalEdildi:
      return 'İptal Edildi';
    case ConsentStatus.suresiDoldu:
      return 'Süresi Doldu';
  }
}
