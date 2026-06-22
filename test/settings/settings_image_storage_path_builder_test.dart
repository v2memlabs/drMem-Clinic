import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/settings/data/settings_image_storage_path_builder.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_settings_json_mapper.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_settings_repository.dart';

void main() {
  test('avatar path is tenant and profile scoped', () {
    final path = SettingsImageStoragePathBuilder.avatarPath(
      tenantId: 't-1',
      profileId: 'p-2',
      extension: 'png',
    );
    expect(path, 'tenants/t-1/profiles/p-2/avatar.png');
  });

  test('branding paths are tenant scoped', () {
    expect(
      SettingsImageStoragePathBuilder.logoPath(tenantId: 't-1', extension: 'jpg'),
      'tenants/t-1/branding/logo.jpg',
    );
    expect(
      SettingsImageStoragePathBuilder.bannerPath(tenantId: 't-1', extension: 'webp'),
      'tenants/t-1/branding/banner.webp',
    );
  });

  test('mergeBranding preserves contact and preferences', () {
    const existing = {
      'contact': {'phone': '0212'},
      'language_code': 'tr',
    };
    const branding = TenantBrandingInfo(
      logoStoragePath: 'tenants/x/branding/logo.png',
      bannerStoragePath: 'tenants/x/branding/banner.jpg',
    );

    final merged = TenantSettingsJsonMapper.mergeBranding(existing, branding);

    expect((merged['contact'] as Map)['phone'], '0212');
    expect(merged['language_code'], 'tr');
    expect((merged['branding'] as Map)['logo_path'], branding.logoStoragePath);
    expect((merged['branding'] as Map)['banner_path'], branding.bannerStoragePath);
  });
}
