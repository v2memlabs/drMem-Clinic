import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/must_change_password_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('readsRequired detects metadata flag', () {
    final user = User(
      id: 'u1',
      appMetadata: const {},
      userMetadata: const {MustChangePasswordGate.metadataKey: true},
      aud: 'authenticated',
      createdAt: '',
    );

    expect(MustChangePasswordGate.readsRequired(user), isTrue);
  });

  test('clearedMetadata sets flag false', () {
    final user = User(
      id: 'u1',
      appMetadata: const {},
      userMetadata: const {
        MustChangePasswordGate.metadataKey: true,
        'display_name': 'Test',
      },
      aud: 'authenticated',
      createdAt: '',
    );

    final cleared = MustChangePasswordGate.clearedMetadata(user);
    expect(cleared[MustChangePasswordGate.metadataKey], isFalse);
    expect(cleared['display_name'], 'Test');
  });
}
