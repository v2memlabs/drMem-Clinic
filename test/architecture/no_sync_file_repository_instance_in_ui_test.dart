import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const allowlist = {
    'lib/features/patient_files/data/mock_patient_file_metadata_repository.dart',
    'lib/features/patient_files/data/mock_patient_file_metadata_mapper.dart',
  };

  test('production UI does not read FileRepository.instance directly', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('FileRepository.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use PatientFileMetadataListDataSource / patientFileMetadata instead of '
          'FileRepository.instance in: ${violations.join(', ')}',
    );
  });
}
