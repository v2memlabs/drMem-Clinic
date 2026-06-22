import '../models/surgery_note_template.dart';
import '../models/surgery_procedure_note.dart';

final List<SurgeryNoteTemplate> mockSurgeryNoteTemplates = [
  SurgeryNoteTemplate(
    id: 'snt1',
    profileId: 'mock-surgeon-primary',
    name: 'Diz artroskopisi — standart',
    description: 'Menisküs ve debridman işlemleri için varsayılan alanlar',
    createdAt: DateTime(2026, 1, 10),
    content: const SurgeryNoteTemplateContent(
      procedureType: ProcedureType.artroskopi,
      bodyRegion: SurgeryBodyRegion.diz,
      side: SurgerySide.sol,
      asaScore: 'ASA II',
      tourniquetUsed: true,
      diagnosis: 'Medial menisküs yırtığı',
      procedureName: 'Diz artroskopisi',
      anesthesiaType: 'Spinal anestezi',
      procedureDetails:
          'İki portal artroskopi, debridman ve parsiyel menisektomi uygulandı',
      complications: 'İntraoperatif komplikasyon yok',
      assistantInfo: 'Asistan: Asistan Kullanıcısı',
      implantLines: ['Standart artroskopi seti'],
      postOpRecommendations:
          '48 saat istirahat, buz uygulaması, kısa süreli mobilizasyon',
      physiotherapyStartRecommendation:
          '5. günden itibaren kontrollü ROM egzersizleri',
      controlSchedule: '2. hafta, 6. hafta kontrol',
    ),
  ),
];
