enum Channel { whatsapp, sms, email }

enum Category {
  randevu_hatirlatma,
  kontrol_hatirlatma,
  randevu_degisim,
  konum_bilgisi,
  ameliyat_oncesi_hazirlik,
  ameliyat_sonrasi_oneri,
  egzersiz_programi,
  fizyoterapi_yonlendirme,
  pdf_bilgilendirme,
  genel_bilgilendirme,
}

class MessageTemplate {
  final String id;
  final String title;
  final Channel channel;
  final Category category;
  final String content;
  final String createdBy;
  final bool isActive;

  MessageTemplate({
    required this.id,
    required this.title,
    required this.channel,
    required this.category,
    required this.content,
    required this.createdBy,
    this.isActive = true,
  });

  String get channelLabel => messageChannelLabel(channel);

  String get categoryLabel => messageCategoryLabel(category);
}

String messageChannelLabel(Channel channel) {
  switch (channel) {
    case Channel.whatsapp:
      return 'WhatsApp';
    case Channel.sms:
      return 'SMS';
    case Channel.email:
      return 'E-posta';
  }
}

String messageCategoryLabel(Category category) {
  switch (category) {
    case Category.randevu_hatirlatma:
      return 'Randevu Hatırlatma';
    case Category.kontrol_hatirlatma:
      return 'Kontrol Hatırlatma';
    case Category.randevu_degisim:
      return 'Randevu Değişiklik';
    case Category.konum_bilgisi:
      return 'Konum Bilgisi';
    case Category.ameliyat_oncesi_hazirlik:
      return 'Ameliyat Öncesi Hazırlık';
    case Category.ameliyat_sonrasi_oneri:
      return 'Ameliyat Sonrası Öneri';
    case Category.egzersiz_programi:
      return 'Egzersiz Programı';
    case Category.fizyoterapi_yonlendirme:
      return 'Fizyoterapi Yönlendirme';
    case Category.pdf_bilgilendirme:
      return 'PDF Bilgilendirme';
    case Category.genel_bilgilendirme:
      return 'Genel Bilgilendirme';
  }
}
