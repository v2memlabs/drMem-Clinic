import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/config/supabase_env_config.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_summary_rpc_response_parser.dart';
import 'package:v2mem_clinic/features/timeline/data/supabase_timeline_repository.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_event_mapper.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_failure.dart';
import 'package:v2mem_clinic/features/timeline/models/timeline_event_enums.dart';
import 'package:supabase/supabase.dart';

void main() {
  tearDown(() {
    SupabaseEnvConfig.supabaseUrl = '';
    SupabaseEnvConfig.supabaseAnonKey = '';
    ActiveTenantContextStore.clear();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  group('SupabaseTimelineRepository RPC contract', () {
    test('listRpcName is list_patient_timeline_events', () {
      expect(
        SupabaseTimelineRepository.listRpcName,
        'list_patient_timeline_events',
      );
    });

    test('listRpcParams sends p_patient_id only', () {
      expect(
        SupabaseTimelineRepository.listRpcParams(patientId: 'patient-uuid'),
        {'p_patient_id': 'patient-uuid'},
      );
      expect(
        SupabaseTimelineRepository.listRpcParams(patientId: 'patient-uuid')
            .containsKey('tenant_id'),
        isFalse,
      );
      expect(
        SupabaseTimelineRepository.listRpcParams(patientId: 'patient-uuid')
            .containsKey('p_tenant_id'),
        isFalse,
      );
    });
  });

  group('SupabaseTimelineRepository validation', () {
    test('empty patientId throws invalidInput before RPC', () async {
      final repo = SupabaseTimelineRepository(
        SupabaseClient('https://example.supabase.co', 'anon-key'),
      );

      await expectLater(
        repo.listPatientTimelineEvents(patientId: '  '),
        throwsA(
          isA<TimelineRepositoryException>().having(
            (e) => e.reason,
            'reason',
            TimelineRepositoryFailure.invalidInput,
          ),
        ),
      );
    });

    test('no active tenant throws noActiveTenant when supabase configured', () async {
      SupabaseEnvConfig.supabaseUrl = 'https://example.supabase.co';
      SupabaseEnvConfig.supabaseAnonKey = 'anon-key';
      AppBackendConfig.activeBackend = DataBackend.supabase;
      ActiveTenantContextStore.clear();

      final repo = SupabaseTimelineRepository(
        SupabaseClient(SupabaseEnvConfig.supabaseUrl, SupabaseEnvConfig.supabaseAnonKey),
      );

      await expectLater(
        repo.listPatientTimelineEvents(patientId: 'patient-uuid'),
        throwsA(
          isA<TimelineRepositoryException>().having(
            (e) => e.reason,
            'reason',
            TimelineRepositoryFailure.noActiveTenant,
          ),
        ),
      );
    });
  });

  group('Timeline RPC response parse smoke', () {
    test('empty RPC list maps to empty domain list', () {
      final rows = ClinicalSummaryRpcResponseParser.coerceRowList([]);
      expect(rows, isEmpty);

      final events = rows.map(TimelineEventMapper.fromRpcRow).toList();
      expect(events, isEmpty);
    });

    test('RPC row maps to TimelineEvent without forbidden metadata', () {
      final rows = ClinicalSummaryRpcResponseParser.coerceRowList([
        {
          'event_id': 'clinical:ce-1:created',
          'tenant_id': '11111111-1111-1111-1111-111111111111',
          'patient_id': '22222222-2222-2222-2222-222222222222',
          'event_type': 'clinical.encounter.created',
          'event_group': 'clinical',
          'title': 'Muayene kaydı oluşturuldu',
          'subtitle': 'Kontrol',
          'occurred_at': '2026-05-26T10:00:00Z',
          'source_entity_type': 'clinical_encounter',
          'source_entity_id': '33333333-3333-3333-3333-333333333333',
          'actor_display_name': 'Dr. A',
          'visibility_scope': 'doctor_admin',
          'icon_key': 'clinical',
          'status': 'active',
          'metadata': {
            'visit_type': 'control',
            'internal_doctor_note': 'secret',
            'storage_path': 'hidden',
          },
        },
      ]);

      final event = TimelineEventMapper.fromRpcRow(rows.first);
      expect(event.eventType, TimelineEventType.clinicalEncounterCreated);
      expect(event.metadata.containsKey('internal_doctor_note'), isFalse);
      expect(event.metadata.containsKey('storage_path'), isFalse);
      expect(event.metadata['visit_type'], 'control');
    });

    test('malformed row throws invalidRow', () {
      expect(
        () => TimelineEventMapper.fromRpcRow({'event_id': 'only-id'}),
        throwsA(
          isA<TimelineRepositoryException>().having(
            (e) => e.reason,
            'reason',
            TimelineRepositoryFailure.invalidRow,
          ),
        ),
      );
    });
  });
}
