import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/physiotherapist_clinical_summary_list_user_messages.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/physiotherapist_clinical_summary_repository_failure.dart';

void main() {
  group('PhysiotherapistClinicalSummaryListUserMessages', () {
    test('loading copy is FTR-specific', () {
      expect(
        PhysiotherapistClinicalSummaryListUserMessages.loading,
        'FTR klinik özetleri yükleniyor…',
      );
    });

    test('forbidden uses FTR clinical tone', () {
      final message = PhysiotherapistClinicalSummaryListUserMessages.forFailure(
        PhysiotherapistClinicalSummaryRepositoryFailure.forbidden,
      );
      expect(message, contains('FTR'));
      expect(message.contains('forbidden'), isFalse);
    });

    test('notConfigured is non-technical', () {
      expect(
        PhysiotherapistClinicalSummaryListUserMessages.forFailure(
          PhysiotherapistClinicalSummaryRepositoryFailure.notConfigured,
        ),
        'FTR klinik özetleri şu anda görüntülenemiyor.',
      );
    });

    test('invalidRow maps to malformed response copy', () {
      expect(
        PhysiotherapistClinicalSummaryListUserMessages.forFailure(
          PhysiotherapistClinicalSummaryRepositoryFailure.invalidRow,
        ),
        PhysiotherapistClinicalSummaryListUserMessages.malformedResponse,
      );
    });
  });
}
