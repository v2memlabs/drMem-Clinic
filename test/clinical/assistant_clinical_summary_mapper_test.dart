import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_dto.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_mapper.dart';

void main() {
  group('AssistantClinicalSummaryDto.fromMap', () {
    test('maps allowlist RPC columns', () {
      final dto = AssistantClinicalSummaryDto.fromMap({
        'encounter_id': 'ce-1',
        'tenant_id': 'tenant-1',
        'patient_id': 'patient-1',
        'patient_display_name': 'Ayşe Yılmaz',
        'encounter_date': '2026-05-21T10:30:00Z',
        'visit_type': 'kontrol',
        'status': 'tamamlandi',
        'diagnosis_summary': 'Diz kontrol',
        'operational_headline': null,
        'next_control_date': '2026-06-01T09:00:00Z',
        'appointment_id': 'appt-1',
        'has_physiotherapy_referral': true,
        'updated_at': '2026-05-21T11:00:00Z',
      });

      expect(dto.encounterId, 'ce-1');
      expect(dto.diagnosisSummary, 'Diz kontrol');
      expect(dto.hasPhysiotherapyReferral, isTrue);
    });

    test('ignores internal_doctor_note and clinical_data keys', () {
      final dto = AssistantClinicalSummaryDto.fromMap({
        'encounter_id': 'ce-2',
        'tenant_id': 'tenant-1',
        'patient_id': 'patient-1',
        'patient_display_name': 'Test',
        'encounter_date': '2026-05-21T10:30:00Z',
        'internal_doctor_note': 'must not map',
        'clinical_data': {'anamnesis': {'chiefComplaint': 'secret'}},
      });

      expect(dto.encounterId, 'ce-2');
    });
  });

  group('AssistantClinicalSummaryMapper', () {
    test('maps dto to domain without clinical encounter fields', () {
      final summary = AssistantClinicalSummaryMapper.fromMap({
        'encounter_id': 'ce-3',
        'tenant_id': 'tenant-1',
        'patient_id': 'patient-1',
        'patient_display_name': 'Mehmet Kaya',
        'encounter_date': '2026-05-21T10:30:00.000Z',
        'diagnosis_summary': '  Özet  ',
        'has_physiotherapy_referral': false,
      });

      expect(summary.encounterId, 'ce-3');
      expect(summary.patientDisplayName, 'Mehmet Kaya');
      expect(summary.diagnosisSummary, 'Özet');
      expect(summary.hasPhysiotherapyReferral, isFalse);
      expect(summary.encounterDate.isUtc, isFalse);
    });
  });
}
