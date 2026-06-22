import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const allowlist = {
    'lib/features/clinical_reports/data/clinical_report_repository_provider.dart',
    'lib/features/clinical_reports/data/mock_async_clinical_report_repository_adapter.dart',
  };

  test('production UI does not read ClinicalReportRepository.instance directly', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('ClinicalReportRepository.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use ClinicalReportListDataSource / clinicalReportsAsync instead of '
          'ClinicalReportRepository.instance in: ${violations.join(', ')}',
    );
  });
}
