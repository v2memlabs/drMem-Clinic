import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_list_user_messages.dart';
import 'package:v2mem_clinic/features/patient_files/data/patient_file_metadata_repository_failure.dart';

void main() {
  group('PatientFileMetadataListUserMessages', () {
    test('loading copy', () {
      expect(
        PatientFileMetadataListUserMessages.loading,
        'Dosya kayıtları yükleniyor…',
      );
    });

    test('notConfigured is non-technical', () {
      final message = PatientFileMetadataListUserMessages.forFailure(
        PatientFileMetadataRepositoryFailure.notConfigured,
      );
      expect(message, PatientFileMetadataListUserMessages.notConfigured);
      expect(message.contains('notConfigured'), isFalse);
    });

    test('forbidden without enum leak', () {
      final message = PatientFileMetadataListUserMessages.forFailure(
        PatientFileMetadataRepositoryFailure.forbidden,
      );
      expect(message, contains('yetkiniz'));
      expect(message.contains('forbidden'), isFalse);
    });

    test('error description is generic', () {
      expect(
        PatientFileMetadataListUserMessages.errorDescription,
        contains('Lütfen tekrar deneyin'),
      );
      expect(
        PatientFileMetadataListUserMessages.errorDescription
            .contains('Postgrest'),
        isFalse,
      );
    });
  });
}
