import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/physiotherapist_clinical_summary_dto.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/physiotherapist_clinical_summary_mapper.dart';

void main() {
  group('PhysiotherapistClinicalSummaryDto.fromMap', () {
    test('maps allowlist RPC columns', () {
      final dto = PhysiotherapistClinicalSummaryDto.fromMap({
        'encounter_id': 'ce-1',
        'tenant_id': 'tenant-1',
        'patient_id': 'patient-1',
        'patient_display_name': 'Ayşe Yılmaz',
        'encounter_date': '2026-05-21T10:30:00Z',
        'body_region': 'diz',
        'side': 'sag',
        'visit_type': 'kontrol',
        'status': 'tamamlandi',
        'physiotherapy_referral': true,
        'exercise_recommendation_short': 'Quadriceps',
        'rehab_precautions_short': 'Yük verme',
        'weight_bearing_status': null,
        'rom_limitation_short': '120°',
        'control_date': '2026-06-01T09:00:00Z',
        'post_op_context_short': 'Post-op hafta 2',
        'ftr_goal_short': 'Spora dönüş',
        'diagnosis_summary': 'Menisküs',
        'treatment_plan_summary': 'FTR planı',
        'updated_at': '2026-05-21T11:00:00Z',
      });

      expect(dto.encounterId, 'ce-1');
      expect(dto.bodyRegion, 'diz');
      expect(dto.physiotherapyReferral, isTrue);
      expect(dto.exerciseRecommendationShort, 'Quadriceps');
    });

    test('optional fields null do not crash', () {
      final dto = PhysiotherapistClinicalSummaryDto.fromMap({
        'encounter_id': 'ce-2',
        'tenant_id': 'tenant-1',
        'patient_id': 'patient-1',
        'patient_display_name': '',
        'encounter_date': '2026-05-21T10:30:00Z',
      });

      expect(dto.bodyRegion, isNull);
      expect(dto.physiotherapyReferral, isFalse);
      expect(dto.controlDate, isNull);
    });

    test('ignores internal_doctor_note and clinical_data keys', () {
      final dto = PhysiotherapistClinicalSummaryDto.fromMap({
        'encounter_id': 'ce-3',
        'tenant_id': 'tenant-1',
        'patient_id': 'patient-1',
        'patient_display_name': 'Test',
        'encounter_date': '2026-05-21T10:30:00Z',
        'internal_doctor_note': 'must not map',
        'clinical_data': {'examination': {'clinicalImpression': 'secret'}},
      });

      expect(dto.encounterId, 'ce-3');
    });

    test('physiotherapy_referral bool parse is safe', () {
      expect(
        PhysiotherapistClinicalSummaryDto.fromMap({
          'encounter_id': 'ce-4',
          'tenant_id': 't',
          'patient_id': 'p',
          'patient_display_name': 'X',
          'encounter_date': '2026-05-21T10:30:00Z',
          'physiotherapy_referral': 'true',
        }).physiotherapyReferral,
        isTrue,
      );
      expect(
        PhysiotherapistClinicalSummaryDto.fromMap({
          'encounter_id': 'ce-5',
          'tenant_id': 't',
          'patient_id': 'p',
          'patient_display_name': 'X',
          'encounter_date': '2026-05-21T10:30:00Z',
        }).physiotherapyReferral,
        isFalse,
      );
    });
  });

  group('PhysiotherapistClinicalSummaryMapper', () {
    test('maps dto to domain with patient display fallback', () {
      final summary = PhysiotherapistClinicalSummaryMapper.fromMap({
        'encounter_id': 'ce-6',
        'tenant_id': 'tenant-1',
        'patient_id': 'patient-1',
        'patient_display_name': '',
        'encounter_date': '2026-05-21T10:30:00.000Z',
        'diagnosis_summary': '  Özet  ',
        'physiotherapy_referral': false,
      });

      expect(summary.encounterId, 'ce-6');
      expect(summary.patientDisplayName, 'Hasta');
      expect(summary.diagnosisSummary, 'Özet');
      expect(summary.encounterDate.isUtc, isFalse);
    });
  });
}
