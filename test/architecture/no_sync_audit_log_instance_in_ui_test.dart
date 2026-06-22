import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const allowlist = {
    'lib/features/audit/data/audit_log_repository_provider.dart',
    'lib/features/audit/data/mock_async_audit_log_repository_adapter.dart',
  };

  test('production UI does not read AuditLogRepository.instance directly', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('AuditLogRepository.instance')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use AuditLogListDataSource / auditLogsAsync instead of '
          'AuditLogRepository.instance in: ${violations.join(', ')}',
    );
  });
}
