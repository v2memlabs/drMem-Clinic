import '../models/my_profile_settings.dart';
import '../models/user_display_preferences.dart';
import 'profile_settings_repository.dart';

class ProfileSettingsRepositoryStub implements ProfileSettingsRepository {
  const ProfileSettingsRepositoryStub();

  Never _notConfigured() => throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.notConfigured,
        'Profil ayarları şu anda kullanıma hazır değil.',
      );

  @override
  Future<String> loadMyDisplayName() async => _notConfigured();

  @override
  Future<void> updateMyDisplayName(String displayName) async => _notConfigured();

  @override
  Future<MyProfileSettings> loadMyProfile() async => _notConfigured();

  @override
  Future<void> updateMyProfile(MyProfileSettings profile) async =>
      _notConfigured();

  @override
  Future<void> updateAvatarStoragePath(String storagePath) async =>
      _notConfigured();

  @override
  Future<UserDisplayPreferences?> loadMyDisplayPreferences() async =>
      _notConfigured();

  @override
  Future<void> updateMyDisplayPreferences(
    UserDisplayPreferences preferences,
  ) async =>
      _notConfigured();
}
