enum ActionType {
  giris,
  hastaDosyasiAcma,
  kayitOlusturma,
  kayitGuncelleme,
  dosyaYukleme,
  dosyaSilme,
  pdfOlusturma,
  mesajGonderme,
  yetkiDegisikligi,
  odemeKaydi,
}

enum ModuleType { auth, hasta, randevu, anamnez, muayene, goruntuleme, dosya, tani, tedavi, pdf, kvkk, odeme, mesajlasma }

class AuditLog {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String userName;
  final String userRole;
  final ActionType actionType;
  final ModuleType module;
  final String? patientId;
  final String? patientName;
  final String description;
  final String? ipAddress;
  final String? deviceInfo;

  AuditLog({required this.id, required this.createdAt, required this.userId, required this.userName, required this.userRole, required this.actionType, required this.module, this.patientId, this.patientName, required this.description, this.ipAddress, this.deviceInfo});
}

String actionTypeLabel(ActionType type) {
  switch (type) {
    case ActionType.giris:
      return 'Giriş';
    case ActionType.hastaDosyasiAcma:
      return 'Hasta Dosyası Açma';
    case ActionType.kayitOlusturma:
      return 'Kayıt Oluşturma';
    case ActionType.kayitGuncelleme:
      return 'Kayıt Güncelleme';
    case ActionType.dosyaYukleme:
      return 'Dosya Yükleme';
    case ActionType.dosyaSilme:
      return 'Dosya Silme';
    case ActionType.pdfOlusturma:
      return 'PDF Oluşturma';
    case ActionType.mesajGonderme:
      return 'Mesaj Gönderme';
    case ActionType.yetkiDegisikligi:
      return 'Yetki Değişikliği';
    case ActionType.odemeKaydi:
      return 'Ödeme Kaydı';
  }
}

String moduleTypeLabel(ModuleType module) {
  switch (module) {
    case ModuleType.auth:
      return 'Kimlik Doğrulama';
    case ModuleType.hasta:
      return 'Hasta';
    case ModuleType.randevu:
      return 'Randevu';
    case ModuleType.anamnez:
      return 'Anamnez';
    case ModuleType.muayene:
      return 'Muayene';
    case ModuleType.goruntuleme:
      return 'Görüntüleme';
    case ModuleType.dosya:
      return 'Dosya';
    case ModuleType.tani:
      return 'Tanı';
    case ModuleType.tedavi:
      return 'Tedavi';
    case ModuleType.pdf:
      return 'PDF';
    case ModuleType.kvkk:
      return 'KVKK';
    case ModuleType.odeme:
      return 'Ödeme';
    case ModuleType.mesajlasma:
      return 'Mesajlaşma';
  }
}
