import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const allowlist = {
    'lib/features/radiology_orders/data/radiology_order_repository_provider.dart',
    'lib/features/radiology_orders/data/mock_async_radiology_order_repository_adapter.dart',
  };

  test('production UI does not read RadiologyOrderRepository.instance directly', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('RadiologyOrderRepository.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use RadiologyOrderListDataSource / radiologyOrdersAsync instead of '
          'RadiologyOrderRepository.instance in: ${violations.join(', ')}',
    );
  });
}
