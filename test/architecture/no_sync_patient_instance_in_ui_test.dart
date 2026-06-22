import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sync [PatientRepository.instance] yalnızca lookup helper ve mock adapter'da.
void main() {
  const allowlist = {
    'lib/features/patients/data/patient_lookup_data_source.dart',
    'lib/features/patients/data/patient_repository_provider.dart',
    'lib/features/patients/data/mock_patient_repository_adapter.dart',
    'lib/features/patients/data/mock_async_patient_repository_adapter.dart',
  };

  test('production UI does not read PatientRepository.instance directly', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('PatientRepository.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use PatientLookupDataSource / PatientLookupBuilder instead of '
          'PatientRepository.instance in: ${violations.join(', ')}',
    );
  });
}
