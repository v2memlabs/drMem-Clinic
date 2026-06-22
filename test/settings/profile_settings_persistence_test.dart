import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_refresher.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/features/settings/data/profile_settings_repository.dart';
import 'package:v2mem_clinic/features/settings/data/profile_settings_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/models/my_profile_settings.dart';
import 'package:v2mem_clinic/features/settings/models/user_display_preferences.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakeProfileRepository implements ProfileSettingsRepository {
  String displayName = 'Eski Ad';
  String avatarStoragePath = '';
  UserDisplayPreferences? displayPreferences;

  @override
  Future<String> loadMyDisplayName() async => displayName;

  @override
  Future<MyProfileSettings> loadMyProfile() async {
    return MyProfileSettings(
      displayName: displayName,
      avatarStoragePath: avatarStoragePath,
    );
  }

  @override
  Future<void> updateMyProfile(MyProfileSettings profile) async {
    await updateMyDisplayName(profile.displayName);
  }

  @override
  Future<void> updateMyDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.validation,
        'Görünen kullanıcı adı boş olamaz.',
      );
    }
    this.displayName = trimmed;
  }

  @override
  Future<void> updateAvatarStoragePath(String storagePath) async {
    final trimmed = storagePath.trim();
    if (trimmed.isEmpty) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.validation,
        'Görsel yolu geçersiz.',
      );
    }
    avatarStoragePath = trimmed;
  }

  @override
  Future<UserDisplayPreferences?> loadMyDisplayPreferences() async {
    return displayPreferences;
  }

  @override
  Future<void> updateMyDisplayPreferences(
    UserDisplayPreferences preferences,
  ) async {
    displayPreferences = preferences;
  }
}

void main() {
  tearDown(() {
    ProfileSettingsRepositoryProvider.testOverride = null;
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
  });

  test('display name save updates session and active context', () async {
    ProfileSettingsRepositoryProvider.testOverride = _FakeProfileRepository();
    AuthSession.setUser(
      AppUser(
        id: 'profile-1',
        username: 'd@test.local',
        displayName: 'Eski Ad',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 'tenant-1', name: 'Klinik'),
        membership: const Membership(
          id: 'm-1',
          tenantId: 'tenant-1',
          userId: 'profile-1',
          role: AppRoles.doctor,
        ),
        profile: const UserProfile(userId: 'profile-1', displayName: 'Eski Ad'),
      ),
    );

    final repo = ProfileSettingsRepositoryProvider.repository;
    await repo.updateMyDisplayName('Yeni Ad');
    AuthSession.updateDisplayName('Yeni Ad');
    ActiveTenantContextRefresher.refreshProfileDisplayName('Yeni Ad');

    expect(AuthSession.currentUser?.displayName, 'Yeni Ad');
    expect(ActiveTenantContextStore.current?.profile.displayName, 'Yeni Ad');
    expect(await repo.loadMyDisplayName(), 'Yeni Ad');
  });
}
