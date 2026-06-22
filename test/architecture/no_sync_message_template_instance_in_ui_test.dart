import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const allowlist = {
    'lib/features/messages/data/message_template_repository_provider.dart',
    'lib/features/messages/data/mock_async_message_template_repository_adapter.dart',
  };

  test('production UI does not read MessageRepository.instance for templates',
      () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('MessageRepository.instance.getTemplate') ||
          content.contains('MessageRepository.instance.getTemplates') ||
          content.contains('MessageRepository.instance.getFilteredTemplates') ||
          content.contains('MessageRepository.instance.searchTemplates')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use MessageTemplateListDataSource / messageTemplatesAsync instead '
          'of MessageRepository.instance template reads in: '
          '${violations.join(', ')}',
    );
  });
}
