import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_mapper.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_summary_rpc_response_parser.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/physiotherapist_clinical_summary_mapper.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/supabase_assistant_clinical_summary_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/supabase_physiotherapist_clinical_summary_repository.dart';

void main() {
  group('ClinicalSummaryRpcResponseParser', () {
    test('coerceRowList empty/null', () {
      expect(ClinicalSummaryRpcResponseParser.coerceRowList(null), isEmpty);
      expect(ClinicalSummaryRpcResponseParser.coerceRowList([]), isEmpty);
    });

    test('coerceSingleRow returns null for empty', () {
      expect(ClinicalSummaryRpcResponseParser.coerceSingleRow([]), isNull);
    });

    test('coerceSingleRow returns first row', () {
      final row = ClinicalSummaryRpcResponseParser.coerceSingleRow([
        {'encounter_id': 'ce-1'},
      ]);
      expect(row?['encounter_id'], 'ce-1');
    });
  });

  group('SupabaseAssistantClinicalSummaryRepository RPC names', () {
    test('list/get RPC constants and params', () {
      expect(
        SupabaseAssistantClinicalSummaryRepository.listRpcName,
        'list_assistant_clinical_summaries',
      );
      expect(
        SupabaseAssistantClinicalSummaryRepository.getRpcName,
        'get_assistant_clinical_summary',
      );
      expect(
        SupabaseAssistantClinicalSummaryRepository.listRpcParams(),
        isEmpty,
      );
      expect(
        SupabaseAssistantClinicalSummaryRepository.listRpcParams(
          patientId: 'patient-1',
        ),
        {'p_patient_id': 'patient-1'},
      );
      expect(
        SupabaseAssistantClinicalSummaryRepository.getRpcParams('ce-1'),
        {'p_encounter_id': 'ce-1'},
      );
    });

    test('maps RPC row list to assistant domain', () {
      final rows = ClinicalSummaryRpcResponseParser.coerceRowList([
        {
          'encounter_id': 'ce-1',
          'tenant_id': 'tenant-1',
          'patient_id': 'patient-1',
          'patient_display_name': 'Ayşe',
          'encounter_date': '2026-05-21T10:30:00Z',
          'has_physiotherapy_referral': true,
          'internal_doctor_note': 'hidden',
          'clinical_data': {'plan': {}},
        },
      ]);

      final summaries =
          rows.map(AssistantClinicalSummaryMapper.fromMap).toList();

      expect(summaries, hasLength(1));
      expect(summaries.first.encounterId, 'ce-1');
    });

    test('get empty RPC response maps to null domain', () {
      final row = ClinicalSummaryRpcResponseParser.coerceSingleRow([]);
      expect(row, isNull);
    });
  });

  group('SupabasePhysiotherapistClinicalSummaryRepository RPC names', () {
    test('list/get RPC constants and params', () {
      expect(
        SupabasePhysiotherapistClinicalSummaryRepository.listRpcName,
        'list_physiotherapist_clinical_summaries',
      );
      expect(
        SupabasePhysiotherapistClinicalSummaryRepository.getRpcName,
        'get_physiotherapist_clinical_summary',
      );
      expect(
        SupabasePhysiotherapistClinicalSummaryRepository.listRpcParams(
          patientId: 'p-1',
        ),
        {'p_patient_id': 'p-1'},
      );
    });

    test('maps RPC row list to physiotherapist domain', () {
      final rows = ClinicalSummaryRpcResponseParser.coerceRowList([
        {
          'encounter_id': 'ce-2',
          'tenant_id': 'tenant-1',
          'patient_id': 'patient-1',
          'patient_display_name': 'Mehmet',
          'encounter_date': '2026-05-21T10:30:00Z',
          'body_region': 'diz',
          'physiotherapy_referral': true,
          'clinical_data': {'examination': {}},
        },
      ]);

      final summaries =
          rows.map(PhysiotherapistClinicalSummaryMapper.fromMap).toList();

      expect(summaries.first.bodyRegion, 'diz');
      expect(summaries.first.physiotherapyReferral, isTrue);
    });
  });
}
