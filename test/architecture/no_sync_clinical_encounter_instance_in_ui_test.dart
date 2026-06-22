import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sync [ClinicalEncounterRepository.instance] yalnızca lookup helper ve mock adapter'da.
void main() {
  const allowlist = {
    'lib/features/clinical_encounter/data/clinical_encounter_lookup_data_source.dart',
    'lib/features/clinical_encounter/data/clinical_encounter_repository_provider.dart',
    'lib/features/clinical_encounter/data/mock_async_clinical_encounter_repository_adapter.dart',
    'lib/features/clinical_encounter/data/mock_assistant_clinical_summary_repository.dart',
  };

  test('production UI does not read ClinicalEncounterRepository.instance directly', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('ClinicalEncounterRepository.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use ClinicalEncounterLookupDataSource / clinicalEncountersAsync instead of '
          'ClinicalEncounterRepository.instance in: ${violations.join(', ')}',
    );
  });
}
