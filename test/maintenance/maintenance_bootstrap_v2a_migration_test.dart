import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maintenance bootstrap v2a migration split into v2a-1 and v2a-2', () {
    expect(
      File(
        'supabase/migrations/20260804100000_maintenance_bootstrap_console_v2a1_tenant_create.sql',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'supabase/migrations/20260804200000_maintenance_bootstrap_console_v2a2_admin_bootstrap.sql',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'supabase/migrations/20260804100000_maintenance_bootstrap_console_v2a.sql',
      ).existsSync(),
      isFalse,
    );
  });
}
