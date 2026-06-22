import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_body_region_mapping.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_clinical_data.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_remote_mapper.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_status_mapping.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_summary_builder.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_visit_type_mapping.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';

ClinicalEncounter _sampleEncounter({String internalNote = 'Gizli not'}) {
  return ClinicalEncounter(
    id: 'ce-client',
    protocolNumber: 'M-2026-00123',
    patientId: 'patient-uuid',
    patientName: 'Ayşe Yılmaz',
    createdAt: DateTime(2026, 5, 21, 10, 30),
    updatedAt: DateTime(2026, 5, 21, 11, 0),
    doctorName: 'Dr. Test',
    status: ClinicalEncounterStatus.tamamlandi,
    visitType: ClinicalVisitType.ilkMuayene,
    bodyRegion: ClinicalBodyRegion.diz,
    side: ClinicalSide.sag,
    chiefComplaint: 'Diz ağrısı',
    complaintDuration: '3 ay',
    traumaHistory: false,
    painLocation: 'Medial',
    painCharacter: 'Süzüntü',
    vasScore: 6,
    nightPain: false,
    activityRelation: 'Merdiven',
    previousTreatments: 'NSAID',
    medications: 'Parasetamol',
    allergies: 'Yok',
    comorbidities: 'HT',
    previousSurgeries: 'Yok',
    generalNotes: 'Not',
    sportsSectionEnabled: false,
    sportBranch: '',
    amateurOrProfessional: '',
    trainingFrequency: '',
    patientExpectation: 'Rahatlama',
    returnToSportGoal: '',
    sportsRelated: false,
    returnToSportPlan: '',
    inspection: 'Effüzyon',
    palpation: 'Hassasiyet',
    rangeOfMotion: '120°',
    muscleStrength: '4/5',
    stabilityTests: 'Negatif',
    specialTests: 'McMurray',
    neurovascularStatus: 'Normal',
    comparisonWithOtherSide: 'Sol normal',
    clinicalImpression: 'Menisküs şüphesi',
    imagingSummary: 'MR medial',
    imagingDoctorComment: 'Yorum',
    attachedFileNote: 'Dosya',
    preliminaryDiagnosis: 'Ön tanı',
    finalDiagnosis: 'Kesin tanı',
    differentialDiagnosis: 'Ayırıcı',
    diagnosisType: ClinicalDiagnosisType.dejeneratif,
    icdCode: 'M23.2',
    icdTitle: 'Menisküs',
    planTitle: 'Konservatif plan',
    conservativeTreatment: 'Egzersiz',
    medicationNotes: 'NSAID',
    injectionOrProcedurePlan: '',
    physiotherapyReferral: true,
    exerciseRecommendation: 'Quadriceps',
    imagingRequest: '',
    controlDate: DateTime(2026, 6, 1),
    surgeryRecommendation: '',
    patientInformationNote: 'Bilgi',
    warningNotes: 'Uyarı',
    internalDoctorNote: internalNote,
  );
}

void main() {
  group('ClinicalVisitTypeMapping', () {
    test('round trip ilkMuayene', () {
      expect(
        ClinicalVisitTypeMapping.fromDb(
          ClinicalVisitTypeMapping.toDb(ClinicalVisitType.ilkMuayene),
        ),
        ClinicalVisitType.ilkMuayene,
      );
    });

    test('unknown falls back to genelOrtopedikDegerlendirme', () {
      expect(
        ClinicalVisitTypeMapping.fromDb('legacy'),
        ClinicalVisitType.genelOrtopedikDegerlendirme,
      );
    });
  });

  group('ClinicalEncounterStatusMapping', () {
    test('unknown falls back to taslak', () {
      expect(
        ClinicalEncounterStatusMapping.fromDb('legacy'),
        ClinicalEncounterStatus.taslak,
      );
    });
  });

  group('ClinicalEncounterSummaryBuilder', () {
    test('diagnosis prefers finalDiagnosis', () {
      final e = _sampleEncounter();
      expect(
        ClinicalEncounterSummaryBuilder.diagnosisSummary(e),
        'Kesin tanı',
      );
    });

    test('treatment summary prefers conservative treatment', () {
      final e = _sampleEncounter();
      expect(
        ClinicalEncounterSummaryBuilder.treatmentPlanSummary(e),
        'Egzersiz',
      );
    });
  });

  group('ClinicalEncounterClinicalData', () {
    test('toMap excludes internalDoctorNote', () {
      final map = ClinicalEncounterClinicalData.toMap(_sampleEncounter());
      expect(map.containsKey('internalDoctorNote'), isFalse);
      expect(map.containsKey('internal_doctor_note'), isFalse);
      final encoded = map.toString();
      expect(encoded.contains('Gizli not'), isFalse);
    });
  });

  group('ClinicalEncounterRemoteMapper.fromRow', () {
    test('maps core fields clinical_data and internal note column', () {
      final encounter = ClinicalEncounterRemoteMapper.fromRow({
        'id': 'ce-uuid',
        'protocol_number': 'M-2026-00456',
        'tenant_id': 'tenant-1',
        'patient_id': 'patient-uuid',
        'encounter_date': '2026-05-21T07:30:00Z',
        'visit_type': 'first_visit',
        'status': 'completed',
        'diagnosis_summary': 'Kesin tanı',
        'treatment_plan_summary': 'Konservatif plan',
        'internal_doctor_note': 'Doktor iç notu',
        'clinical_data': ClinicalEncounterClinicalData.toMap(_sampleEncounter(
          internalNote: 'JSONB içinde olmamalı',
        )),
        'patients': {'first_name': 'Ayşe', 'last_name': 'Yılmaz'},
      });

      expect(encounter.id, 'ce-uuid');
      expect(encounter.protocolNumber, 'M-2026-00456');
      expect(encounter.patientName, 'Ayşe Yılmaz');
      expect(encounter.chiefComplaint, 'Diz ağrısı');
      expect(encounter.icdCode, 'M23.2');
      expect(encounter.internalDoctorNote, 'Doktor iç notu');
      expect(encounter.doctorName, 'Dr. Test');
      expect(encounter.status, ClinicalEncounterStatus.tamamlandi);
      expect(encounter.visitType, ClinicalVisitType.ilkMuayene);
      expect(encounter.bodyRegion, ClinicalBodyRegion.diz);
    });

    test('missing embed uses Hasta fallback', () {
      final encounter = ClinicalEncounterRemoteMapper.fromRow({
        'id': 'ce-1',
        'tenant_id': 't1',
        'patient_id': 'p1',
        'encounter_date': '2026-01-01T12:00:00Z',
        'status': 'draft',
        'visit_type': 'follow_up',
        'clinical_data': {},
      });

      expect(encounter.patientName, 'Hasta');
    });
  });

  group('ClinicalEncounterRemoteMapper write rows', () {
    test('toInsertRow omits id and sets tenant_id', () {
      final row = ClinicalEncounterRemoteMapper.toInsertRow(
        _sampleEncounter(),
        tenantId: 'tenant-scope',
      );

      expect(row.containsKey('id'), isFalse);
      expect(row['tenant_id'], 'tenant-scope');
      expect(row['patient_id'], 'patient-uuid');
      expect(row['protocol_number'], 'M-2026-00123');
      expect(row['visit_type'], 'first_visit');
      expect(row['status'], 'completed');
      expect(row['diagnosis_summary'], 'Kesin tanı');
      expect(row['internal_doctor_note'], 'Gizli not');
      expect(row['clinical_data'], isA<Map<String, dynamic>>());
      final clinicalData = row['clinical_data'] as Map<String, dynamic>;
      expect(clinicalData.toString().contains('Gizli not'), isFalse);
    });

    test('toUpdateRow omits tenant_id and patient_id', () {
      final row = ClinicalEncounterRemoteMapper.toUpdateRow(_sampleEncounter());

      expect(row.containsKey('tenant_id'), isFalse);
      expect(row.containsKey('patient_id'), isFalse);
      expect(row.containsKey('appointment_id'), isFalse);
      expect(row['internal_doctor_note'], 'Gizli not');
    });

    test('toArchiveRow sets deleted_at only', () {
      final row = ClinicalEncounterRemoteMapper.toArchiveRow(
        at: DateTime.utc(2026, 5, 21, 10),
      );
      expect(row.containsKey('status'), isFalse);
      expect(row['deleted_at'], '2026-05-21T10:00:00.000Z');
    });
  });

  group('ClinicalBodyRegionMapping', () {
    test('round trip diz', () {
      expect(
        ClinicalBodyRegionMapping.fromDb(
          ClinicalBodyRegionMapping.toDb(ClinicalBodyRegion.diz),
        ),
        ClinicalBodyRegion.diz,
      );
    });
  });
}
