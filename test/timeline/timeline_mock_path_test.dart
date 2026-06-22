import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_list_data_source.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_list_user_messages.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_provider.dart';
import 'package:v2mem_clinic/features/timeline/presentation/patient_timeline_list_content.dart';

void main() {
  tearDown(() {
    TimelineRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('Timeline mock path UI', () {
    testWidgets('mock backend shows timeline events for patient', (tester) async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      TimelineRepositoryProvider.resetCache();

      final result = await TimelineListDataSource.load(patientId: 'p1');

      await tester.pumpWidget(
        wrap(
          PatientTimelineListContent(
            isLoading: false,
            result: result,
            events: result.events,
            onRetry: () {},
          ),
        ),
      );

      expect(find.textContaining('Muayene'), findsWidgets);
      expect(find.textContaining('tenant_id'), findsNothing);
      expect(find.textContaining('profile_id'), findsNothing);
      expect(
        find.text(TimelineListUserMessages.notConfigured),
        findsNothing,
      );
    });

    testWidgets('mock backend empty patient shows safe empty state',
        (tester) async {
      AppBackendConfig.activeBackend = DataBackend.mock;
      TimelineRepositoryProvider.resetCache();

      final result = await TimelineListDataSource.load(
        patientId: 'p-empty-unknown',
      );

      await tester.pumpWidget(
        wrap(
          PatientTimelineListContent(
            isLoading: false,
            result: result,
            events: result.events,
            onRetry: () {},
          ),
        ),
      );

      expect(
        find.text(TimelineListUserMessages.emptyForPatient),
        findsOneWidget,
      );
      expect(
        find.text(TimelineListUserMessages.notConfigured),
        findsNothing,
      );
    });
  });
}
