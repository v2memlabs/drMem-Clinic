import '../../../shared/widgets/info_section_card.dart';
import '../models/clinical_encounter.dart';
import '../models/clinical_treatment_approach.dart';
import 'clinical_encounter_diagnosis_display.dart';

/// Muayene detay — 7 bölüm satır grupları.
abstract final class ClinicalEncounterDetailSections {
  static String _display(String v) =>
      v.trim().isEmpty ? kDisplayUnspecified : v.trim();

  static String? _approachLabel(ClinicalEncounter e) =>
      e.treatmentApproach?.label;

  static List<InfoSectionRow> identity(ClinicalEncounter e) => [
        if (e.hasProtocolNumber)
          InfoSectionRow(
            'Protokol No',
            e.displayProtocolNumber,
            emphasize: true,
          ),
        InfoSectionRow('Başvuru Tipi', e.visitType.label),
        InfoSectionRow('Durum', e.status.label),
        InfoSectionRow('Hekim', _display(e.doctorName)),
      ];

  static List<InfoSectionRow> complaintStory(ClinicalEncounter e) => [
        InfoSectionRow('Ana Şikayet', _display(e.chiefComplaint), emphasize: true),
        InfoSectionRow('Şikayet Süresi', _display(e.complaintDuration)),
        InfoSectionRow('Travma Öyküsü', e.traumaHistory ? 'Var' : 'Yok'),
        InfoSectionRow('Ağrı Yeri', _display(e.painLocation)),
        InfoSectionRow('Ağrı Karakteri', _display(e.painCharacter)),
        InfoSectionRow('VAS Skoru', '${e.vasScore}'),
        InfoSectionRow('Gece Ağrısı', e.nightPain ? 'Evet' : 'Hayır'),
        InfoSectionRow('Aktivite ile İlişki', _display(e.activityRelation)),
        InfoSectionRow('Önceki Tedaviler', _display(e.previousTreatments)),
        InfoSectionRow('Kullandığı İlaçlar', _display(e.medications)),
        InfoSectionRow('Alerjiler', _display(e.allergies)),
        InfoSectionRow('Eşlik Eden Hastalıklar', _display(e.comorbidities)),
        InfoSectionRow('Önceki Cerrahiler', _display(e.previousSurgeries)),
        InfoSectionRow('Genel Notlar', _display(e.generalNotes)),
        if (e.sportsSectionEnabled) ...[
          InfoSectionRow('Spor Branşı', _display(e.sportBranch)),
          InfoSectionRow('Amatör / Profesyonel', _display(e.amateurOrProfessional)),
          InfoSectionRow('Antrenman Sıklığı', _display(e.trainingFrequency)),
          InfoSectionRow('Hasta Beklentisi', _display(e.patientExpectation)),
          InfoSectionRow('Spora Dönüş Hedefi', _display(e.returnToSportGoal)),
          InfoSectionRow('Spor İlişkili', e.sportsRelated ? 'Evet' : 'Hayır'),
          InfoSectionRow('Spora Dönüş Planı', _display(e.returnToSportPlan)),
        ],
      ];

  static List<InfoSectionRow> examination(ClinicalEncounter e) => [
        InfoSectionRow('İnspeksiyon', _display(e.inspection)),
        InfoSectionRow('Palpasyon', _display(e.palpation)),
        InfoSectionRow('Hareket Açıklığı (ROM)', _display(e.rangeOfMotion)),
        InfoSectionRow('Kas Gücü', _display(e.muscleStrength)),
        InfoSectionRow('Stabilite Testleri', _display(e.stabilityTests)),
        InfoSectionRow('Özel Testler', _display(e.specialTests)),
        InfoSectionRow('Nörovasküler Durum', _display(e.neurovascularStatus)),
        InfoSectionRow(
          'Karşı Taraf Karşılaştırma',
          _display(e.comparisonWithOtherSide),
        ),
        InfoSectionRow(
          'Klinik İzlenim',
          _display(e.clinicalImpression),
          emphasize: true,
        ),
      ];

  static List<InfoSectionRow> imaging(ClinicalEncounter e) => [
        InfoSectionRow('Görüntüleme Özeti', _display(e.imagingSummary)),
        InfoSectionRow(
          'Görüntüleme Hekim Yorumu',
          _display(e.imagingDoctorComment),
        ),
        InfoSectionRow('Ek Dosya Notu', _display(e.attachedFileNote)),
      ];

  static List<InfoSectionRow> diagnosis(ClinicalEncounter e) =>
      ClinicalEncounterDiagnosisDisplay.detailRows(e);

  static List<InfoSectionRow> treatmentPlan(ClinicalEncounter e) => [
        InfoSectionRow(
          'Tedavi Yaklaşımı',
          _approachLabel(e) ?? kDisplayUnspecified,
        ),
        InfoSectionRow('Konservatif Tedavi', _display(e.conservativeTreatment)),
        InfoSectionRow('Tedavi İlaç Notu', _display(e.medicationNotes)),
        InfoSectionRow(
          'Enjeksiyon / Girişim Planı',
          _display(e.injectionOrProcedurePlan),
        ),
        InfoSectionRow('Ortez / Atel / Destek', _display(e.orthosisNotes)),
        InfoSectionRow(
          'Ameliyat / Girişim Önerisi',
          _display(e.surgeryRecommendation),
        ),
      ];

  static List<InfoSectionRow> physiotherapyControl(ClinicalEncounter e) => [
        InfoSectionRow(
          'Fizyoterapi Yönlendirmesi',
          e.physiotherapyReferral ? 'Evet' : 'Hayır',
          emphasize: true,
        ),
        InfoSectionRow('Egzersiz Önerisi', _display(e.exerciseRecommendation)),
        InfoSectionRow(
          'Görüntüleme İstemi',
          _display(e.imagingRequest),
        ),
        InfoSectionRow(
          'Kontrol Tarihi',
          e.controlDate != null
              ? _formatDate(e.controlDate!)
              : kDisplayUnspecified,
        ),
        InfoSectionRow('Kayıt Durumu', e.status.label),
        InfoSectionRow(
          'Hasta Bilgilendirme',
          _display(e.patientInformationNote),
        ),
        InfoSectionRow('Uyarılar', _display(e.warningNotes)),
      ];

  static String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month.${d.year}';
  }
}
