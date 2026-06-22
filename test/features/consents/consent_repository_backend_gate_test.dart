import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/consents/data/consent_repository_backend_gate.dart';

void main() {
  test('consents capability true inventory capability true in v2b', () {
    expect(OperationalRecordsRemoteCapabilities.consentsTableReady, isTrue);
    expect(OperationalRecordsRemoteCapabilities.inventoryTablesReady, isTrue);
  });

  test('remote requires full gate chain', () {
    expect(
      ConsentRepositoryBackendGate.shouldUseRemoteConsents(
        isMockBackend: false,
        isSupabaseConfigured: true,
        isSupabaseInitialized: true,
        isLoggedIn: true,
        isSessionReady: true,
        hasActiveTenant: true,
        isConsentRoleEligible: true,
      ),
      isTrue,
    );

    expect(
      ConsentRepositoryBackendGate.shouldUseRemoteConsents(
        isMockBackend: false,
        isSupabaseConfigured: true,
        isSupabaseInitialized: true,
        isLoggedIn: true,
        isSessionReady: true,
        hasActiveTenant: true,
        isConsentRoleEligible: false,
      ),
      isFalse,
    );
  });
}
