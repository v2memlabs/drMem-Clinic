import 'consent_record.dart';

/// Hazır onam form şablonu kategorileri.
abstract final class ConsentTemplateCategories {
  static const kvkkAydinlatma = 'KVKK Aydınlatma';
  static const acikRiza = 'Açık Rıza';
  static const ameliyatOnami = 'Ameliyat Onamı';
  static const girisimEnjeksiyon = 'Girişim / Enjeksiyon Onamı';
  static const fotoVideo = 'Fotoğraf / Video İzni';
  static const fizyoterapistPaylasim = 'Fizyoterapist ile Veri Paylaşımı';
  static const whatsappSms = 'WhatsApp / SMS İletişim İzni';
  static const email = 'E-posta İletişim İzni';

  static const List<String> all = [
    kvkkAydinlatma,
    acikRiza,
    ameliyatOnami,
    girisimEnjeksiyon,
    fotoVideo,
    fizyoterapistPaylasim,
    whatsappSms,
    email,
  ];
}

/// Şablonun hangi durumda gerekli olduğu.
abstract final class ConsentTemplateRequiredFor {
  static const tumHastalar = 'Tüm hastalar';
  static const ameliyatOncesi = 'Ameliyat öncesi';
  static const girisimOncesi = 'Girişim öncesi';
  static const fizyoterapiYonlendirme = 'Fizyoterapi yönlendirmesi';
  static const mesajlasmaIzni = 'Mesajlaşma izni';
  static const fotoVideoKaydi = 'Fotoğraf/video kaydı';
  static const gerekliDegil = 'Gerekli değil';
}

class ConsentTemplate {
  final String id;
  final String title;
  final String category;
  final String description;
  final String version;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String documentFileName;
  final String contentPreview;
  final String requiredFor;
  final String? notes;

  const ConsentTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.version,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.documentFileName,
    required this.contentPreview,
    required this.requiredFor,
    this.notes,
  });
}

/// Şablon kategorisini mevcut [ConsentType] enum değerine eşler.
ConsentType consentTypeFromTemplateCategory(String category) {
  switch (category) {
    case ConsentTemplateCategories.kvkkAydinlatma:
      return ConsentType.kvkkAydinlatma;
    case ConsentTemplateCategories.acikRiza:
      return ConsentType.acikRiza;
    case ConsentTemplateCategories.ameliyatOnami:
      return ConsentType.ameliyatOnami;
    case ConsentTemplateCategories.girisimEnjeksiyon:
      return ConsentType.ameliyatOnami;
    case ConsentTemplateCategories.fotoVideo:
      return ConsentType.fotoVideoIzin;
    case ConsentTemplateCategories.fizyoterapistPaylasim:
      return ConsentType.fizyoterapistPaylasim;
    case ConsentTemplateCategories.whatsappSms:
      return ConsentType.whatsappIzin;
    case ConsentTemplateCategories.email:
      return ConsentType.emailIzin;
    default:
      return ConsentType.acikRiza;
  }
}
