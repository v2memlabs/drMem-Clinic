import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sync [AppointmentRepository.instance] yalnızca lookup helper ve mock adapter'da.
void main() {
  const allowlist = {
    'lib/features/appointments/data/appointment_lookup_data_source.dart',
    'lib/features/appointments/data/appointment_repository_provider.dart',
    'lib/features/appointments/data/mock_appointment_repository_adapter.dart',
    'lib/features/appointments/data/mock_async_appointment_repository_adapter.dart',
  };

  test('production UI does not read AppointmentRepository.instance directly', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('AppointmentRepository.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use AppointmentLookupDataSource / appointmentsAsync instead of '
          'AppointmentRepository.instance in: ${violations.join(', ')}',
    );
  });
}
