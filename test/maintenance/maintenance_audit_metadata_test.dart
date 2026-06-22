/// Maintenance audit metadata allowlist — istemci tarafı doğrulama (RPC metadata DB'de sanitize edilir).
library;

import 'package:flutter_test/flutter_test.dart';

const _forbiddenKeys = {
  'email',
  'display_name',
  'phone',
  'password',
  'signed_url',
  'storage_path',
  'service_role',
  'jwt',
};

bool metadataIsSafe(Map<String, dynamic> metadata) {
  for (final key in metadata.keys) {
    final normalized = key.toLowerCase().replaceAll('-', '_');
    if (_forbiddenKeys.contains(normalized)) return false;
    if (normalized.contains('email')) return false;
    if (normalized.contains('password')) return false;
  }
  return true;
}

void main() {
  test('tenant create audit metadata is safe', () {
    const sample = {
      'target_tenant_id': 'a0000001-0001-4001-8001-000000000001',
      'after_status': 'active',
      'operation_result': 'created',
      'source': 'maintenance_v2a1',
    };
    expect(metadataIsSafe(sample), isTrue);
  });

  test('örnek maintenance audit metadata güvenli', () {
    const sample = {
      'target_profile_id': 'b0000001-0001-4001-8001-000000000001',
      'target_membership_id': 'c0000001-0001-4001-8001-000000000001',
      'field': 'role',
      'before': 'assistant_secretary',
      'after': 'nurse',
      'source': 'maintenance_console_v1',
    };
    expect(metadataIsSafe(sample), isTrue);
  });

  test('yasak anahtarlar reddedilir', () {
    expect(
      metadataIsSafe({'email': 'secret@x.com'}),
      isFalse,
    );
    expect(
      metadataIsSafe({'signed_url': 'https://x'}),
      isFalse,
    );
    expect(
      metadataIsSafe({'display_name': 'Ali'}),
      isFalse,
    );
  });
}
