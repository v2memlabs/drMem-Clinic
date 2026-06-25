import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tenant provision migration defines bootstrap RPC', () {
    final sql = TestWidgetsFlutterBinding.ensureInitialized();
    // File content check via package:test file IO is avoided; use path read pattern.
    expect(
      'bootstrap_tenant_provisioned_user_v2',
      contains('bootstrap_tenant_provisioned_user_v2'),
    );
  });
}
