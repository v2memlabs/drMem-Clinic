import '../models/my_profile_settings.dart';
import '../models/user_display_preferences.dart';

/// Profil ayarları — kullanıcı kendi `profiles` satırını günceller.
abstract interface class ProfileSettingsRepository {
  Future<String> loadMyDisplayName();

  Future<void> updateMyDisplayName(String displayName);

  Future<MyProfileSettings> loadMyProfile();

  Future<void> updateMyProfile(MyProfileSettings profile);

  Future<void> updateAvatarStoragePath(String storagePath);

  /// Kullanıcıya özel görünüm — yoksa `null` (tenant varsayılanı kullanılır).
  Future<UserDisplayPreferences?> loadMyDisplayPreferences();

  Future<void> updateMyDisplayPreferences(UserDisplayPreferences preferences);
}

enum ProfileSettingsFailure {
  forbidden,
  noActiveProfile,
  notFound,
  validation,
  notConfigured,
  unknown,
}

class ProfileSettingsRepositoryException implements Exception {
  const ProfileSettingsRepositoryException(this.failure, this.message);

  final ProfileSettingsFailure failure;
  final String message;

  @override
  String toString() => message;
}
