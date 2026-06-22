import '../models/consent_template.dart';

final List<ConsentTemplate> mockConsentTemplates = [
  ConsentTemplate(
    id: 'ct1',
    title: 'KVKK Aydınlatma Metni',
    category: ConsentTemplateCategories.kvkkAydinlatma,
    description: 'Kişisel verilerin işlenmesine ilişkin standart aydınlatma metni.',
    version: 'v2.1',
    isActive: true,
    createdAt: DateTime(2025, 1, 10),
    updatedAt: DateTime(2026, 2, 1),
    documentFileName: 'kvkk_aydinlatma_v2.1.pdf',
    contentPreview:
        '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında; kimlik, iletişim, '
        'sağlık ve klinik işlem verilerinizin sağlık hizmetlerinin yürütülmesi, '
        'randevu ve hasta kayıt süreçlerinin işletilmesi, yasal yükümlülüklerin '
        'yerine getirilmesi ve hasta güvenliğinin sağlanması amaçlarıyla işlenebileceği '
        'hakkında bilgilendirildim. Kanunda tanımlanan başvuru ve itiraz haklarım '
        'tarafıma açıklandı.',
    requiredFor: ConsentTemplateRequiredFor.tumHastalar,
    notes: 'İlk başvuruda zorunlu.',
  ),
  ConsentTemplate(
    id: 'ct2',
    title: 'Açık Rıza Formu',
    category: ConsentTemplateCategories.acikRiza,
    description: 'Belirli işlemler için açık rıza beyanı.',
    version: 'v1.3',
    isActive: true,
    createdAt: DateTime(2025, 3, 5),
    updatedAt: DateTime(2025, 11, 20),
    documentFileName: 'acik_riza_v1.3.pdf',
    contentPreview:
        'Tarafıma açıklanan kapsam ve amaçlarla sınırlı olmak üzere, sağlık hizmeti '
        'sürecinde gerekli kişisel ve özel nitelikli verilerimin işlenmesine ilişkin '
        'tercihimi özgür irademle beyan ederim.',
    requiredFor: ConsentTemplateRequiredFor.tumHastalar,
  ),
  ConsentTemplate(
    id: 'ct3',
    title: 'Artroskopik Diz Cerrahisi Onam Formu',
    category: ConsentTemplateCategories.ameliyatOnami,
    description: 'Diz artroskopisi için ameliyat öncesi bilgilendirme ve onam.',
    version: 'v3.0',
    isActive: true,
    createdAt: DateTime(2024, 6, 1),
    updatedAt: DateTime(2026, 1, 15),
    documentFileName: 'onam_artroskopik_diz_v3.pdf',
    contentPreview:
        'Diz ekleminde artroskopik cerrahi girişim planlandığı; işlemin tanı amaçlı '
        'inceleme, menisküs onarımı veya parsiyel rezeksiyon, kıkırdak düzeltme, '
        'serbest cisim çıkarılması gibi adımları kapsayabileceği tarafıma açıklandı. '
        'Genel veya bölgesel anestezi seçenekleri, ameliyat öncesi hazırlık, '
        'hastanede kalış süresi ve taburculuk sonrası yürüme/egzersiz programı '
        'hakkında bilgilendirildim. Enfeksiyon, kanama, damar ve sinir yaralanması, '
        'derin ven trombozu, eklem sertliği, ağrının devam etmesi veya tekrarlayan '
        'cerrahi ihtiyacı gibi olası riskler anlatıldı. Konservatif tedavi, enjeksiyon '
        'uygulamaları ve fizik tedavi gibi alternatifler değerlendirildi. Sorularım '
        'yanıtlandıktan sonra planlanan işleme rıza gösterdiğimi beyan ederim.',
    requiredFor: ConsentTemplateRequiredFor.ameliyatOncesi,
    notes: 'Pre-op checklist ile birlikte kullanılır.',
  ),
  ConsentTemplate(
    id: 'ct4',
    title: 'Ön Çapraz Bağ Rekonstrüksiyonu Onam Formu',
    category: ConsentTemplateCategories.ameliyatOnami,
    description: 'ACL rekonstrüksiyonu için detaylı cerrahi onam.',
    version: 'v2.4',
    isActive: true,
    createdAt: DateTime(2024, 8, 12),
    updatedAt: DateTime(2025, 9, 1),
    documentFileName: 'onam_acl_rekonstruksiyon_v2.4.pdf',
    contentPreview:
        'Ön çapraz bağ (ACL) yırtığı tanısı ve instabilite şikâyetlerim nedeniyle '
        'artroskopik ACL rekonstrüksiyonu planlandığı; işlemin diz eklemini '
        'stabilize etmeyi hedeflediği tarafıma anlatıldı. Greft seçenekleri '
        '(semittendinosus/gracilis, patellar tendon, allogreft vb.), tünel '
        'açılması, fiksasyon yöntemleri ve ameliyat sonrası koruyucu dizlik veya '
        'atelle mobilizasyon protokolü açıklandı. Enfeksiyon, kanama, greft '
        'kopması veya gevşemesi, eklem sertliği, ağrı, menisküs hasarı, '
        'anesteziye bağlı komplikasyonlar ile erken veya geç dönem rehabilitasyon '
        'gereksinimi hakkında bilgilendirildim. Konservatif tedavi ve kısmi onarım '
        'alternatifleri değerlendirildi. Yaklaşık 6–12 aylık rehabilitasyon '
        'sürecinin önemine dair beklentiler paylaşıldı. Kararımı bilinçli olarak '
        'verdiğimi beyan ederim.',
    requiredFor: ConsentTemplateRequiredFor.ameliyatOncesi,
  ),
  ConsentTemplate(
    id: 'ct5',
    title: 'Omuz Artroskopisi Onam Formu',
    category: ConsentTemplateCategories.ameliyatOnami,
    description: 'Omuz artroskopik girişimler için onam şablonu.',
    version: 'v1.8',
    isActive: true,
    createdAt: DateTime(2025, 2, 20),
    updatedAt: DateTime(2026, 3, 1),
    documentFileName: 'onam_omuz_artroskopi_v1.8.pdf',
    contentPreview:
        'Omuz ekleminde artroskopik girişim planlandığı; rotator manşet onarımı, '
        'labrum onarımı, subakromial dekompresyon, kapsül serbestleştirme veya '
        'serbest cisim çıkarılması gibi işlemlerden hangilerinin uygulanacağının '
        'intraoperatif bulgulara göre belirlenebileceği tarafıma açıklandı. Genel '
        'veya bölgesel anestezi, ameliyat süresi, omuz askısı kullanımı ve erken '
        'dönem pasif-aktif hareket programı hakkında bilgilendirildim. Enfeksiyon, '
        'kanama, sinir hasarı, eklem sertliği, ağrının sürmesi, donuk omuz sendromu '
        've tekrar cerrahi ihtiyacı gibi riskler anlatıldı. Enjeksiyon, fizik '
        'tedavi ve konservatif takip alternatifleri değerlendirildi. Taburculuk '
        'sonrası yük kısıtlamalarına uymam gerektiği belirtildi. Planlanan işleme '
        'rıza gösterdiğimi beyan ederim.',
    requiredFor: ConsentTemplateRequiredFor.ameliyatOncesi,
  ),
  ConsentTemplate(
    id: 'ct6',
    title: 'Enjeksiyon / Girişim Onam Formu',
    category: ConsentTemplateCategories.girisimEnjeksiyon,
    description: 'Eklem içi enjeksiyon ve minimal girişimler için kısa onam.',
    version: 'v1.1',
    isActive: true,
    createdAt: DateTime(2025, 5, 1),
    updatedAt: DateTime(2025, 12, 10),
    documentFileName: 'onam_enjeksiyon_girisim_v1.1.pdf',
    contentPreview:
        'Eklem içi veya yumuşak doku enjeksiyonu / minimal invaziv girişim planlandığı; '
        'uygulanacak preparatın türü (ör. kortikosteroid, hyaluronik asit, PRP vb.), '
        'işlemin amacı, uygulama yeri ve steril teknikle yapılacağı tarafıma '
        'açıklandı. İşlem sırasında ve sonrasında geçici ağrı, şişlik, morarma, '
        'enfeksiyon, alerjik reaksiyon, kanama veya sinir irritasyonu gibi olası '
        'riskler anlatıldı. Beklenen faydanın kişiden kişiye değişebileceği, '
        'etkinin geçici olabileceği ve tekrar uygulama gerekebileceği belirtildi. '
        'Alternatif tedavi seçenekleri (ilaç tedavisi, fizik tedavi, cerrahi '
        'değerlendirme) hakkında bilgilendirildim. Sorularım yanıtlandıktan sonra '
        'planlanan girişime onay verdiğimi beyan ederim.',
    requiredFor: ConsentTemplateRequiredFor.girisimOncesi,
  ),
  ConsentTemplate(
    id: 'ct7',
    title: 'Fizyoterapist ile Veri Paylaşımı Onamı',
    category: ConsentTemplateCategories.fizyoterapistPaylasim,
    description: 'Muayene ve tedavi bilgilerinin fizyoterapi birimine aktarımı.',
    version: 'v1.0',
    isActive: true,
    createdAt: DateTime(2025, 4, 15),
    updatedAt: DateTime(2025, 4, 15),
    documentFileName: 'onam_fizyoterapi_paylasim_v1.pdf',
    contentPreview:
        'Fizyoterapi ve rehabilitasyon hizmetinin güvenli ve etkin yürütülebilmesi '
        'için; muayene bulgularım, tanı özeti, uygulanan veya planlanan tedavi '
        'protokolü, ilgili görüntüleme ve laboratuvar sonuçları ile egzersiz '
        'kısıtlamalarımın klinik fizyoterapi birimi ve görevlendirilen '
        'fizyoterapist(ler) ile paylaşılabileceği tarafıma açıklandı. Paylaşımın '
        'yalnızca tedavi planının uygulanması, ilerlemenin izlenmesi ve ekip içi '
        'koordinasyon amacıyla sınırlı olacağı; verilerin gizlilik ve mesleki etik '
        'kuralları çerçevesinde korunacağı belirtildi. Paylaşım kapsamı dışında '
        'üçüncü kişilere aktarım yapılmayacağı ve rızamı geri çekme hakkımın '
        'bulunduğu anlatıldı. Belirtilen kapsamda veri paylaşımına onay '
        'verdiğimi beyan ederim.',
    requiredFor: ConsentTemplateRequiredFor.fizyoterapiYonlendirme,
  ),
  ConsentTemplate(
    id: 'ct8',
    title: 'WhatsApp İletişim İzni',
    category: ConsentTemplateCategories.whatsappSms,
    description: 'Randevu ve bilgilendirme için WhatsApp iletişim izni.',
    version: 'v1.2',
    isActive: true,
    createdAt: DateTime(2025, 7, 1),
    updatedAt: DateTime(2026, 1, 5),
    documentFileName: 'izin_whatsapp_v1.2.pdf',
    contentPreview:
        'Randevu hatırlatması, randevu değişikliği/iptali, muayene sonrası kısa '
        'bilgilendirme, reçete veya evrak hatırlatmaları ile tedavi planına ilişkin '
        'genel yönlendirmelerin, tarafımda kayıtlı cep telefonu numarasına WhatsApp '
        'üzerinden iletilmesine izin veriyorum. Mesajların sağlık hizmeti '
        'süreçlerinin yürütülmesi amacıyla sınırlı olacağı; acil durumlarda '
        'WhatsApp yerine 112 veya acil servis başvurusu yapılması gerektiği '
        'tarafıma açıklandı. İletişim tercihimi istediğim zaman geri çekebileceğim '
        've numaramın güncel tutulmasından sorumlu olduğum belirtildi. Belirtilen '
        'kapsamda WhatsApp iletişimine onay verdiğimi beyan ederim.',
    requiredFor: ConsentTemplateRequiredFor.mesajlasmaIzni,
  ),
  ConsentTemplate(
    id: 'ct9',
    title: 'Fotoğraf / Video Kullanım İzni',
    category: ConsentTemplateCategories.fotoVideo,
    description: 'Tedavi sürecinde görüntü kaydı ve eğitim amaçlı kullanım.',
    version: 'v1.0',
    isActive: true,
    createdAt: DateTime(2025, 8, 20),
    updatedAt: DateTime(2025, 10, 1),
    documentFileName: 'izin_foto_video_v1.pdf',
    contentPreview:
        'Tedavi öncesi/sonrası durumun belgelenmesi, iyileşmenin izlenmesi ve '
        'mesleki eğitim amacıyla (hasta kimliği veya tanımlayıcı bilgiler '
        'gösterilmeden) fotoğraf veya video kaydı alınabileceği tarafıma '
        'açıklandı. Kayıtların yalnızca belirtilen amaçlarla, yetkili sağlık '
        'personeli tarafından erişilebilir sistemlerde saklanacağı; sosyal medya '
        'veya tanıtım amaçlı paylaşım yapılmayacağı (ayrı yazılı izin olmadıkça) '
        'belirtildi. Kayıt alınırken mahremiyetime özen gösterileceği ve '
        'rızamı istediğim zaman geri çekebileceğim anlatıldı. Belirtilen kapsamda '
        'fotoğraf/video kullanımına onay verdiğimi beyan ederim.',
    requiredFor: ConsentTemplateRequiredFor.fotoVideoKaydi,
  ),
  ConsentTemplate(
    id: 'ct10',
    title: 'E-posta İletişim İzni',
    category: ConsentTemplateCategories.email,
    description: 'Rapor ve bilgilendirme e-postası gönderim izni.',
    version: 'v1.0',
    isActive: true,
    createdAt: DateTime(2025, 9, 1),
    updatedAt: DateTime(2025, 9, 1),
    documentFileName: 'izin_email_v1.pdf',
    contentPreview:
        'Randevu onayı ve hatırlatması, muayene/epikriz özeti, reçete veya evrak '
        'bilgilendirmesi, laboratuvar/görüntüleme sonuç bildirimleri ile tedavi '
        'planına ilişkin yazılı yönlendirmelerin, tarafımda kayıtlı e-posta '
        'adresime iletilmesine izin veriyorum. E-posta iletişiminin acil müdahale '
        'için uygun olmadığı; gecikmeli okunabileceği ve güvenli olmayan ağlarda '
        'risk taşıyabileceği tarafıma açıklandı. Adresimin güncel tutulmasından '
        'sorumlu olduğum ve iletişim tercihimi istediğim zaman değiştirebileceğim '
        'belirtildi. Belirtilen kapsamda e-posta iletişimine onay verdiğimi beyan '
        'ederim.',
    requiredFor: ConsentTemplateRequiredFor.mesajlasmaIzni,
  ),
];
