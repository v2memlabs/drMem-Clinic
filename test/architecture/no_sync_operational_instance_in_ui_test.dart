import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sync operasyonel repository `.instance` yalnızca mock adapter ve provider'da.
void main() {
  const patterns = {
    'ImagingRepository.instance': {
      'lib/features/imaging/data/imaging_repository_provider.dart',
      'lib/features/imaging/data/mock_async_imaging_repository_adapter.dart',
    },
    'SurgeryRepository.instance': {
      'lib/features/surgery/data/surgery_procedure_note_repository_provider.dart',
      'lib/features/surgery/data/mock_async_surgery_procedure_note_repository_adapter.dart',
    },
    'ExercisePlanRepository.instance': {
      'lib/features/exercises/data/exercise_plan_repository_provider.dart',
      'lib/features/exercises/data/mock_async_exercise_plan_repository_adapter.dart',
    },
    'PostOpProtocolRepository.instance': {
      'lib/features/post_op_protocols/data/post_op_protocol_repository_provider.dart',
      'lib/features/post_op_protocols/data/mock_async_post_op_protocol_repository_adapter.dart',
    },
    'PaymentRepository.instance': {
      'lib/features/payments/data/payment_repository_provider.dart',
      'lib/features/payments/data/mock_async_payment_repository_adapter.dart',
    },
    'InventoryRepository.instance': {
      'lib/features/inventory/data/inventory_repository_provider.dart',
      'lib/features/inventory/data/mock_async_inventory_repository_adapter.dart',
    },
  };

  for (final entry in patterns.entries) {
    test('production UI does not read ${entry.key} directly', () {
      final libDir = Directory('lib');
      final violations = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final normalized = entity.path.replaceAll('\\', '/');
        if (entry.value.contains(normalized)) continue;

        final content = entity.readAsStringSync();
        if (content.contains(entry.key)) {
          violations.add(normalized);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Use async repository / lookup data sources instead of ${entry.key} in: '
            '${violations.join(', ')}',
      );
    });
  }
}
