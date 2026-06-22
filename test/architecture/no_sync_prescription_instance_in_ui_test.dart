import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const allowlist = {
    'lib/features/prescriptions/data/prescription_repository_provider.dart',
    'lib/features/prescriptions/data/mock_async_prescription_repository_adapter.dart',
  };

  test('production UI does not read PrescriptionRepository.instance directly', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('PrescriptionRepository.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use PrescriptionListDataSource / prescriptionsAsync instead of '
          'PrescriptionRepository.instance in: ${violations.join(', ')}',
    );
  });
}
