import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/features/physiotherapy/data/supabase_physiotherapy_session_repository.dart',
  );

  test('repository source exists', () {
    expect(source.existsSync(), isTrue);
  });

  test('insert profile id prefers auth currentUser mapping', () {
    final text = source.readAsStringSync();
    expect(text, contains('Future<String> _resolveProfileIdForInsert()'));
    expect(text, contains('_client.auth.currentUser?.id'));
    expect(text, contains(".from('profiles')"));
    expect(text, contains(".eq('auth_user_id', authUserId)"));
  });

  test('insert profile id keeps ActiveTenant fallback', () {
    final text = source.readAsStringSync();
    expect(text, contains('return _requireProfileId();'));
  });
}
