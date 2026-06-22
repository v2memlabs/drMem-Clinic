import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const allowlist = {
    'lib/features/messages/data/sent_message_repository_provider.dart',
    'lib/features/messages/data/mock_async_sent_message_repository_adapter.dart',
  };

  test('production UI does not read MessageRepository.instance for sent messages',
      () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlist.contains(normalized)) continue;

      final content = entity.readAsStringSync();
      if (content.contains('MessageRepository.instance.getSentMessage') ||
          content.contains('MessageRepository.instance.getSentMessages') ||
          content.contains('MessageRepository.instance.getFilteredSentMessages') ||
          content.contains('MessageRepository.instance.addSentMessage') ||
          content.contains('MessageRepository.instance.searchSentMessages')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use SentMessageListDataSource / sentMessagesAsync instead of '
          'MessageRepository.instance sent message reads in: '
          '${violations.join(', ')}',
    );
  });
}
