import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/supabase_web_auth_callback_uri.dart';

void main() {
  test('fromBrowser strips hash and keeps path + query', () {
    final uri = SupabaseWebAuthCallbackUri.fromBrowser();
    expect(uri.fragment, isEmpty);
    expect(uri.path, Uri.base.path);
    expect(uri.query, Uri.base.query);
  });
}
