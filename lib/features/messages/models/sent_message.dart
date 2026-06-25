enum SendStatus { hazirlandi, gonderildi, basarisiz, iptal }

class SentMessage {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String channel;
  final String category;
  final String templateTitle;
  final DateTime sentAt;
  final String sentBy;
  final SendStatus status;
  final String contentPreview;
  final String content;
  final String patientEmail;
  final String relatedModule;
  final String notes;

  SentMessage({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.channel,
    required this.category,
    required this.templateTitle,
    required this.sentAt,
    required this.sentBy,
    required this.status,
    required this.contentPreview,
    this.content = '',
    this.patientEmail = '',
    this.relatedModule = '',
    this.notes = '',
  });
}

String sendStatusLabel(SendStatus status) {
  switch (status) {
    case SendStatus.hazirlandi:
      return 'Hazırlandı';
    case SendStatus.gonderildi:
      return 'Gönderildi';
    case SendStatus.basarisiz:
      return 'Başarısız';
    case SendStatus.iptal:
      return 'İptal';
  }
}
