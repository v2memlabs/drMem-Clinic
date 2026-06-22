import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_list_user_messages.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_repository_failure.dart';

void main() {
  group('AssistantClinicalSummaryListUserMessages', () {
    test('loading copy', () {
      expect(
        AssistantClinicalSummaryListUserMessages.loading,
        'Klinik özetler yükleniyor…',
      );
    });

    test('forbidden uses clinical tone without enum leak', () {
      final message = AssistantClinicalSummaryListUserMessages.forFailure(
        AssistantClinicalSummaryRepositoryFailure.forbidden,
      );
      expect(message, contains('yetkiniz'));
      expect(message.contains('forbidden'), isFalse);
      expect(message.contains('AssistantClinicalSummary'), isFalse);
    });

    test('notConfigured is non-technical', () {
      final message = AssistantClinicalSummaryListUserMessages.forFailure(
        AssistantClinicalSummaryRepositoryFailure.notConfigured,
      );
      expect(message, 'Klinik özetler şu anda görüntülenemiyor.');
      expect(message.contains('notConfigured'), isFalse);
    });

    test('noActiveTenant mentions active clinic session', () {
      final message = AssistantClinicalSummaryListUserMessages.forFailure(
        AssistantClinicalSummaryRepositoryFailure.noActiveTenant,
      );
      expect(message, contains('aktif klinik oturumu'));
    });

    test('network suggests connection retry', () {
      final message = AssistantClinicalSummaryListUserMessages.forFailure(
        AssistantClinicalSummaryRepositoryFailure.network,
      );
      expect(message, contains('bağlantınızı'));
    });

    test('invalidRow maps to malformed response copy', () {
      expect(
        AssistantClinicalSummaryListUserMessages.forFailure(
          AssistantClinicalSummaryRepositoryFailure.invalidRow,
        ),
        AssistantClinicalSummaryListUserMessages.malformedResponse,
      );
    });
  });
}
