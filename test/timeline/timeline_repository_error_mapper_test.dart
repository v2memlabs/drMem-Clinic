import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_error_mapper.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_repository_failure.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  group('TimelineRepositoryErrorMapper', () {
    test('maps PostgREST 42501 to forbidden', () {
      final ex = TimelineRepositoryErrorMapper.toException(
        const PostgrestException(
          message: 'permission denied',
          code: '42501',
        ),
      );
      expect(ex.reason, TimelineRepositoryFailure.forbidden);
    });

    test('maps PGRST116 to notFound', () {
      final ex = TimelineRepositoryErrorMapper.toException(
        const PostgrestException(
          message: 'not found',
          code: 'PGRST116',
        ),
      );
      expect(ex.reason, TimelineRepositoryFailure.notFound);
    });
  });
}
