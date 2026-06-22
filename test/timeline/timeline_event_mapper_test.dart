import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_event_dto.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_event_mapper.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_failure.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_stub.dart';
import 'package:v2mem_clinic/features/timeline/models/timeline_event.dart';
import 'package:v2mem_clinic/features/timeline/models/timeline_event_enums.dart';

Map<String, dynamic> _fullRpcRow({Map<String, Object?>? metadata}) {
  return {
    'event_id': 'clinical:ce-1:created',
    'tenant_id': '11111111-1111-1111-1111-111111111111',
    'patient_id': '22222222-2222-2222-2222-222222222222',
    'event_type': 'clinical.encounter.created',
    'event_group': 'clinical',
    'title': ' Muayene kaydı oluşturuldu ',
    'subtitle': ' Kontrol · active ',
    'occurred_at': '2026-05-26T14:30:00Z',
    'source_entity_type': 'clinical_encounter',
    'source_entity_id': '33333333-3333-3333-3333-333333333333',
    'actor_display_name': ' Dr. A ',
    'visibility_scope': 'doctor_admin',
    'icon_key': 'clinical',
    'status': 'active',
    'metadata': metadata ??
        {
          'visit_type': 'control',
          'encounter_status': 'active',
          'internal_doctor_note': 'secret',
          'clinical_data': {'x': 1},
          'storage_path': 'hidden/path',
          'signed_url': 'https://example.com',
        },
    'internal_doctor_note': 'must not map',
    'clinical_data': {'forbidden': true},
    'storage_path': 'also forbidden top-level',
  };
}

void main() {
  group('TimelineEventMapper', () {
    test('fromRpcRow maps full RPC row to domain', () {
      final domain = TimelineEventMapper.fromRpcRow(_fullRpcRow());

      expect(domain.eventId, 'clinical:ce-1:created');
      expect(domain.eventType, TimelineEventType.clinicalEncounterCreated);
      expect(domain.eventGroup, TimelineEventGroup.clinical);
      expect(domain.title, 'Muayene kaydı oluşturuldu');
      expect(domain.subtitle, 'Kontrol · active');
      expect(domain.occurredAt, DateTime.parse('2026-05-26T14:30:00Z'));
      expect(domain.sourceEntityType, 'clinical_encounter');
      expect(domain.sourceEntityId, '33333333-3333-3333-3333-333333333333');
      expect(domain.actorDisplayName, 'Dr. A');
      expect(domain.visibilityScope, TimelineVisibilityScope.doctorAdmin);
      expect(domain.iconKey, 'clinical');
      expect(domain.status, 'active');
      expect(domain.metadata['visit_type'], 'control');
      expect(domain.metadata.containsKey('internal_doctor_note'), isFalse);
      expect(domain.metadata.containsKey('clinical_data'), isFalse);
      expect(domain.metadata.containsKey('storage_path'), isFalse);
      expect(domain.metadata.containsKey('signed_url'), isFalse);
    });

    test('optional fields null or missing do not crash', () {
      final row = _fullRpcRow();
      row.remove('subtitle');
      row.remove('source_entity_id');
      row.remove('actor_display_name');
      row.remove('icon_key');
      row.remove('status');
      row['metadata'] = null;

      final domain = TimelineEventMapper.fromRpcRow(row);

      expect(domain.subtitle, isNull);
      expect(domain.sourceEntityId, isNull);
      expect(domain.actorDisplayName, isNull);
      expect(domain.iconKey, isNull);
      expect(domain.status, isNull);
      expect(domain.metadata, isEmpty);
    });

    test('empty title uses safe fallback', () {
      final row = _fullRpcRow();
      row['title'] = '   ';

      final domain = TimelineEventMapper.fromRpcRow(row);

      expect(domain.title, TimelineEventMapper.defaultTitle);
    });

    test('occurred_at parses ISO string', () {
      final dto = TimelineEventDto.fromRpcRow(_fullRpcRow());
      expect(dto.occurredAt.isUtc, isTrue);
    });

    test('forbidden metadata keys stripped in DTO and domain', () {
      final dto = TimelineEventDto.fromRpcRow(_fullRpcRow());
      expect(dto.metadata.containsKey('internal_doctor_note'), isFalse);
      expect(dto.metadata.containsKey('signedUrl'), isFalse);

      final domain = TimelineEventMapper.fromDto(dto);
      expect(domain.metadata.containsKey('fileContent'), isFalse);
      expect(domain.metadata.containsKey('pdfContent'), isFalse);
    });

    test('missing required event_id throws invalidRow', () {
      final row = _fullRpcRow();
      row.remove('event_id');

      expect(
        () => TimelineEventMapper.fromRpcRow(row),
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

  group('TimelineRepository contract', () {
    test('stub implements list only and returns TimelineEvent type', () {
      const TimelineRepository repo = TimelineRepositoryStub();

      expect(repo, isA<TimelineRepository>());
      expect(
        repo.listPatientTimelineEvents(patientId: 'p-1'),
        throwsA(
          isA<TimelineRepositoryException>().having(
            (e) => e.reason,
            'reason',
            TimelineRepositoryFailure.notConfigured,
          ),
        ),
      );
    });

    test('domain type is TimelineEvent not ClinicalEncounter', () {
      final sample = TimelineEvent(
        eventId: 'e1',
        tenantId: 't1',
        patientId: 'p1',
        eventType: TimelineEventType.other,
        eventGroup: TimelineEventGroup.other,
        title: 'T',
        occurredAt: DateTime.utc(2026),
        sourceEntityType: 'patient',
        visibilityScope: TimelineVisibilityScope.other,
      );
      expect(sample, isA<TimelineEvent>());
      expect(ClinicalEncounter, isA<Type>());
      expect(sample, isNot(isA<ClinicalEncounter>()));
    });
  });
}
