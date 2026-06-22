import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/core/settings/app_settings_controller.dart';
import 'package:v2mem_clinic/features/pdf_outputs/services/pdf_letterhead_config.dart';

void main() {
  tearDown(() {
    ActiveTenantContextStore.clearSilently();
  });

  test('letterhead prefers active tenant name over local settings', () {
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(
          id: 'tenant-1',
          name: 'Tenant Klinik Adı',
          specialty: 'Tenant Branş',
        ),
        membership: const Membership(
          id: 'm-1',
          tenantId: 'tenant-1',
          userId: 'p-1',
          role: 'doctor',
        ),
        profile: const UserProfile(userId: 'p-1', displayName: 'Doktor'),
      ),
    );

    final letterhead = PdfLetterheadConfig.fromCurrentSettings();
    expect(letterhead.clinicName, 'Tenant Klinik Adı');
    expect(letterhead.specialty, 'Tenant Branş');
  });

  test('letterhead falls back to local settings when no tenant context', () {
    ActiveTenantContextStore.clearSilently();
    final defaults = appSettingsController.settings;

    final letterhead = PdfLetterheadConfig.fromCurrentSettings();
    expect(letterhead.clinicName, defaults.clinicName);
    expect(letterhead.specialty, defaults.specialty);
  });
}
