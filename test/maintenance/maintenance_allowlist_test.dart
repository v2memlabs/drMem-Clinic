import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/maintenance/widgets/maintenance_copy_id.dart';

/// Maintenance ekranları global forbidden scan dışında tutulur;
/// operatör UUID gösterimi bilinçli, ancak secret/token/JWT/exception yasak.
const maintenanceHardForbidden = [
  'service_role',
  'secret',
  'token',
  'JWT',
  'Exception:',
  'stack trace',
  'stackTrace',
];

void main() {
  testWidgets('MaintenanceCopyId preserves UUID id labels for operators', (tester) async {
    const profileId = 'b0000001-0001-4001-8001-000000000001';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaintenanceCopyId(label: 'profile_id', value: profileId),
        ),
      ),
    );

    expect(find.textContaining('profile_id'), findsOneWidget);
    expect(find.textContaining(profileId), findsOneWidget);
  });

  testWidgets('maintenance widget tree excludes hard forbidden tokens', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: const [
              MaintenanceCopyId(
                label: 'tenant_id',
                value: 'a0000001-0001-4001-8001-000000000001',
              ),
              MaintenanceCopyId(
                label: 'auth_user_id',
                value: 'c0000001-0001-4001-8001-000000000001',
              ),
              Text('Profile ID (opsiyonel)'),
            ],
          ),
        ),
      ),
    );

    for (final token in maintenanceHardForbidden) {
      expect(find.textContaining(token), findsNothing);
    }

    expect(find.textContaining('Profile ID'), findsOneWidget);
    expect(find.textContaining('tenant_id'), findsOneWidget);
  });
}
