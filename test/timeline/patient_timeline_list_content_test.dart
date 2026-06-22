import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_list_load_result.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_list_user_messages.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_failure.dart';
import 'package:v2mem_clinic/features/timeline/models/timeline_event.dart';
import 'package:v2mem_clinic/features/timeline/models/timeline_event_enums.dart';
import 'package:v2mem_clinic/features/timeline/presentation/patient_timeline_list_content.dart';

TimelineEvent _sampleEvent() {
  return TimelineEvent(
    eventId: 'e-1',
    tenantId: 'tenant-hidden',
    patientId: 'p-1',
    eventType: TimelineEventType.clinicalEncounterCreated,
    eventGroup: TimelineEventGroup.clinical,
    title: 'Muayene kaydı',
    subtitle: 'Kontrol',
    occurredAt: DateTime(2026, 5, 1, 10),
    sourceEntityType: 'clinical_encounter',
    sourceEntityId: 'ce-hidden-id',
    actorDisplayName: 'Dr. A',
    visibilityScope: TimelineVisibilityScope.doctorAdmin,
    metadata: const {
      'visit_type': 'control',
      'internal_doctor_note': 'secret',
      'clinical_data': {'x': 1},
      'storage_path': 'bucket/path',
      'signed_url': 'https://evil.example',
    },
  );
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('PatientTimelineListContent', () {
    testWidgets('renders safe timeline fields only', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientTimelineListContent(
            isLoading: false,
            result: TimelineListLoadResult.success([_sampleEvent()]),
            events: [_sampleEvent()],
          ),
        ),
      );

      expect(find.text('Muayene kaydı'), findsOneWidget);
      expect(find.textContaining('tenant-hidden'), findsNothing);
      expect(find.textContaining('ce-hidden-id'), findsNothing);
      expect(find.textContaining('internal_doctor_note'), findsNothing);
      expect(find.textContaining('secret'), findsNothing);
      expect(find.textContaining('clinical_data'), findsNothing);
      expect(find.textContaining('storage_path'), findsNothing);
      expect(find.textContaining('evil.example'), findsNothing);
      expect(find.textContaining('signed_url'), findsNothing);
    });

    testWidgets('loading hides stale list', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientTimelineListContent(
            isLoading: true,
            result: TimelineListLoadResult.success([_sampleEvent()]),
            events: [_sampleEvent()],
          ),
        ),
      );

      expect(find.text(TimelineListUserMessages.loading), findsOneWidget);
      expect(find.text('Muayene kaydı'), findsNothing);
    });

    testWidgets('loading state message', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PatientTimelineListContent(
            isLoading: true,
            result: null,
          ),
        ),
      );

      expect(
        find.text(TimelineListUserMessages.loading),
        findsOneWidget,
      );
    });

    testWidgets('empty state with description', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientTimelineListContent(
            isLoading: false,
            result: TimelineListLoadResult.success(const []),
            events: const [],
          ),
        ),
      );

      expect(
        find.text(TimelineListUserMessages.emptyForPatient),
        findsOneWidget,
      );
      expect(
        find.text(TimelineListUserMessages.emptyForPatientDescription),
        findsOneWidget,
      );
    });

    testWidgets('notConfigured state without crash', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientTimelineListContent(
            isLoading: false,
            result: TimelineListLoadResult.notConfigured(),
            events: const [],
          ),
        ),
      );

      expect(
        find.text(TimelineListUserMessages.notConfigured),
        findsOneWidget,
      );
      expect(
        find.text(TimelineListUserMessages.notConfiguredDescription),
        findsOneWidget,
      );
      expect(find.textContaining('Uzak veri'), findsNothing);
      expect(find.text('Tekrar dene'), findsNothing);
    });

    testWidgets('session required state', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientTimelineListContent(
            isLoading: false,
            result: TimelineListLoadResult.sessionRequired(),
            events: const [],
            onRetry: () {},
          ),
        ),
      );

      expect(
        find.text(TimelineListUserMessages.sessionRequired),
        findsOneWidget,
      );
    });

    testWidgets('forbidden error hides technical text and retry', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientTimelineListContent(
            isLoading: false,
            result: TimelineListLoadResult.failure(
              TimelineListUserMessages.presentationForFailure(
                TimelineRepositoryFailure.forbidden,
              ),
            ),
            events: const [],
            onRetry: () {},
          ),
        ),
      );

      expect(find.text(TimelineListUserMessages.forbidden), findsOneWidget);
      expect(find.textContaining('PostgREST'), findsNothing);
      expect(find.textContaining('forbidden'), findsNothing);
      expect(find.text('Tekrar dene'), findsNothing);
    });

    testWidgets('network error shows retry and friendly copy', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientTimelineListContent(
            isLoading: false,
            result: TimelineListLoadResult.failure(
              TimelineListUserMessages.presentationForFailure(
                TimelineRepositoryFailure.network,
              ),
            ),
            events: const [],
            onRetry: () {},
          ),
        ),
      );

      expect(find.text(TimelineListUserMessages.networkError), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
    });

    testWidgets('invalidRow error uses data format message', (tester) async {
      await tester.pumpWidget(
        wrap(
          PatientTimelineListContent(
            isLoading: false,
            result: TimelineListLoadResult.failure(
              TimelineListUserMessages.presentationForFailure(
                TimelineRepositoryFailure.invalidRow,
              ),
            ),
            events: const [],
            onRetry: () {},
          ),
        ),
      );

      expect(
        find.text(TimelineListUserMessages.invalidRowError),
        findsOneWidget,
      );
      expect(find.textContaining('invalidRow'), findsNothing);
    });
  });
}
