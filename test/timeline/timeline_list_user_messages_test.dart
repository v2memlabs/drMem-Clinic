import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_list_user_messages.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_failure.dart';

void main() {
  group('TimelineListUserMessages', () {
    test('presentation maps forbidden without retry', () {
      final p = TimelineListUserMessages.presentationForFailure(
        TimelineRepositoryFailure.forbidden,
      );
      expect(p.title, TimelineListUserMessages.forbidden);
      expect(p.showRetry, isFalse);
      expect(p.title, isNot(contains('TimelineRepositoryFailure')));
      expect(p.description, isNot(contains('Postgrest')));
    });

    test('presentation maps network with retry', () {
      final p = TimelineListUserMessages.presentationForFailure(
        TimelineRepositoryFailure.network,
      );
      expect(p.showRetry, isTrue);
      expect(p.description, TimelineListUserMessages.networkError);
    });

    test('presentation maps invalidRow with user-friendly copy', () {
      final p = TimelineListUserMessages.presentationForFailure(
        TimelineRepositoryFailure.invalidRow,
      );
      expect(p.description, TimelineListUserMessages.invalidRowError);
      expect(p.description, isNot(contains('invalidRow')));
    });

    test('presentation maps noActiveTenant to session copy', () {
      final p = TimelineListUserMessages.presentationForFailure(
        TimelineRepositoryFailure.noActiveTenant,
      );
      expect(p.title, TimelineListUserMessages.sessionRequired);
    });

    test('presentation maps notConfigured without retry', () {
      final p = TimelineListUserMessages.presentationForFailure(
        TimelineRepositoryFailure.notConfigured,
      );
      expect(p.title, TimelineListUserMessages.notConfigured);
      expect(p.showRetry, isFalse);
    });
  });
}
