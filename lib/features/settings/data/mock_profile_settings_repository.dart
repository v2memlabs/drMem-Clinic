import '../../../core/auth/auth_session.dart';
import '../../../core/auth/user_display_names.dart';
import '../../../core/session/active_tenant_context_refresher.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../models/my_profile_settings.dart';
import '../models/user_display_preferences.dart';
import 'profile_settings_repository.dart';

class MockProfileSettingsRepository implements ProfileSettingsRepository {
  const MockProfileSettingsRepository();

  static String avatarStoragePath = '';
  static final Map<String, UserDisplayPreferences> displayPreferencesByUserId =
      {};

  @override
  Future<String> loadMyDisplayName() async {
    final ctxName = ActiveTenantContextStore.current?.profile.displayName;
    if (ctxName != null && ctxName.trim().isNotEmpty) {
      return ctxName.trim();
    }
    final user = AuthSession.currentUser;
    if (user == null) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.noActiveProfile,
        'Oturum bulunamadı.',
      );
    }
    return appSettingsController.displayNameForRole(user.role);
  }

  @override
  Future<MyProfileSettings> loadMyProfile() async {
    final displayName = await loadMyDisplayName();
    final user = AuthSession.currentUser;
    return MyProfileSettings(
      displayName: displayName,
      email: user?.username ?? '',
      avatarStoragePath: avatarStoragePath,
    );
  }

  @override
  Future<void> updateMyProfile(MyProfileSettings profile) async {
    await updateMyDisplayName(profile.displayName);
  }

  @override
  Future<void> updateMyDisplayName(String displayName) async {
    final user = AuthSession.currentUser;
    if (user == null) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.noActiveProfile,
        'Oturum bulunamadı.',
      );
    }
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.validation,
        'Görünen kullanıcı adı boş olamaz.',
      );
    }
    final value = trimmed.isEmpty
        ? UserDisplayNames.defaultForRole(user.role)
        : trimmed;
    await appSettingsController.saveDisplayNameForRole(
      role: user.role,
      displayName: value,
    );
    ActiveTenantContextRefresher.refreshProfileDisplayName(value);
  }

  @override
  Future<UserDisplayPreferences?> loadMyDisplayPreferences() async {
    final user = AuthSession.currentUser;
    if (user == null) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.noActiveProfile,
        'Oturum bulunamadı.',
      );
    }
    final stored =
        await appSettingsController.loadStoredUserDisplayPreferences(user.id);
    return stored ?? displayPreferencesByUserId[user.id];
  }

  @override
  Future<void> updateMyDisplayPreferences(
    UserDisplayPreferences preferences,
  ) async {
    final user = AuthSession.currentUser;
    if (user == null) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.noActiveProfile,
        'Oturum bulunamadı.',
      );
    }
    displayPreferencesByUserId[user.id] = preferences;
    await appSettingsController.saveUserDisplayPreferences(
      userId: user.id,
      preferences: preferences,
    );
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
}
