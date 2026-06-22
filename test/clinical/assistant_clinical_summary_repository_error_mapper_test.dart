import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_repository_error_mapper.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_repository_failure.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  test('maps PostgREST permission to forbidden', () {
    final ex = AssistantClinicalSummaryRepositoryErrorMapper.toException(
      const PostgrestException(
        message: 'row-level security violation',
        code: '42501',
      ),
    );
    expect(ex.reason, AssistantClinicalSummaryRepositoryFailure.forbidden);
  });
}
