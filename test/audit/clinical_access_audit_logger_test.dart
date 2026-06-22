import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/audit/access/audit_access_event_type.dart';
import 'package:v2mem_clinic/features/audit/access/clinical_access_audit_logger.dart';
import 'package:v2mem_clinic/features/audit/access/mock_audit_access_event_recorder.dart';

void main() {
  group('ClinicalAccessAuditLogger', () {
    late MockAuditAccessEventRecorder recorder;

    setUp(() {
      recorder = MockAuditAccessEventRecorder.instance;
      recorder.clear();
    });

    test('assistant summary list records event without sensitive fields', () async {
      ClinicalAccessAuditLogger.assistantSummaryList(
        patientId: 'p-1',
        resultCount: 2,
      );

      await Future<void>.delayed(Duration.zero);

      expect(recorder.events, isNotEmpty);
      final event = recorder.events.first;
      expect(
        event.eventType,
        AuditAccessEventType.clinicalSummaryAssistantList,
      );
      expect(event.patientId, 'p-1');
      expect(event.metadata.containsKey('internal_doctor_note'), isFalse);
      expect(event.metadata.containsKey('clinical_data'), isFalse);
    });

    test('internal note view is separate event type', () async {
      ClinicalAccessAuditLogger.clinicalInternalNoteView(
        encounterId: 'ce-1',
        patientId: 'p-1',
      );

      await Future<void>.delayed(Duration.zero);

      expect(
        recorder.events.first.eventType,
        AuditAccessEventType.clinicalInternalNoteView,
      );
      expect(
        recorder.events.first.metadata['includes_internal_note_access'],
        true,
      );
    });
  });
}
