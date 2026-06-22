import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/supabase_auth_url_session.dart';

void main() {
  group('SupabaseAuthUrlSession.hasAuthCallbackInUri', () {
    test('detects recovery hash tokens', () {
      final uri = Uri.parse(
        'http://localhost:3000/auth/update-password'
        '#access_token=abc&refresh_token=def&expires_in=3600&token_type=bearer&type=recovery',
      );
      expect(SupabaseAuthUrlSession.hasAuthCallbackInUri(uri), isTrue);
    });

    test('detects pkce code query', () {
      final uri = Uri.parse(
        'http://localhost:3000/auth/update-password?code=auth-code',
      );
      expect(SupabaseAuthUrlSession.hasAuthCallbackInUri(uri), isTrue);
    });

    test('ignores plain password path', () {
      final uri = Uri.parse('http://localhost:3000/auth/update-password');
      expect(SupabaseAuthUrlSession.hasAuthCallbackInUri(uri), isFalse);
    });
  });
}
