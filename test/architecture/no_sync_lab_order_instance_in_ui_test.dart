import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const allowlist = {
    'lib/features/lab_orders/data/lab_order_repository_provider.dart',
    'lib/features/lab_orders/data/lab_order_template_repository_provider.dart',
    'lib/features/lab_orders/data/mock_async_lab_order_repository_adapter.dart',
    'lib/features/lab_orders/data/mock_async_lab_order_template_repository_adapter.dart',
  };

  test('production UI does not read LabOrderRepository.instance directly', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('LabOrderRepository.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use LabOrderListDataSource / labOrdersAsync instead of '
          'LabOrderRepository.instance in: ${violations.join(', ')}',
    );
  });

  test('production UI does not read LabOrderTemplateRepository.instance directly', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('LabOrderTemplateRepository.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use LabOrderTemplateListDataSource / labOrderTemplatesAsync instead of '
          'LabOrderTemplateRepository.instance in: ${violations.join(', ')}',
    );
  });
}
