import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/my_profile_settings.dart';
import '../models/user_display_preferences.dart';
import 'profile_settings_repository.dart';
import 'user_display_preferences_mapper.dart';

class SupabaseProfileSettingsRepository implements ProfileSettingsRepository {
  SupabaseProfileSettingsRepository(this._client);

  factory SupabaseProfileSettingsRepository.fromSupabase() {
    return SupabaseProfileSettingsRepository(Supabase.instance.client);
  }

  static const String table = 'profiles';

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.notConfigured,
        'Uzak veritabanı yapılandırılmadı.',
      );
    }
  }

  String _requireProfileId() {
    _ensureConfigured();
    final profileId = ActiveTenantContextStore.current?.profile.userId;
    if (profileId == null || profileId.trim().isEmpty) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.noActiveProfile,
        'Aktif profil bulunamadı.',
      );
    }
    return profileId.trim();
  }

  @override
  Future<String> loadMyDisplayName() async {
    final profileId = _requireProfileId();
    try {
      final row = await _client
          .from(table)
          .select('display_name')
          .eq('id', profileId)
          .maybeSingle();
      if (row == null) {
        throw const ProfileSettingsRepositoryException(
          ProfileSettingsFailure.notFound,
          'Profil bulunamadı.',
        );
      }
      final name = row['display_name'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
      final sessionName = AuthSession.currentUser?.displayName;
      if (sessionName != null && sessionName.trim().isNotEmpty) {
        return sessionName.trim();
      }
      return '';
    } on ProfileSettingsRepositoryException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ProfileSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e),
      );
    } catch (_) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.unknown,
        'Profil yüklenemedi.',
      );
    }
  }

  MyProfileSettings _mapProfileRow(Map<String, dynamic> row) {
    final sessionEmail = AuthSession.currentUser?.username;
    return MyProfileSettings(
      displayName: _optionalString(row['display_name']),
      firstName: _optionalString(row['first_name']),
      lastName: _optionalString(row['last_name']),
      title: _optionalString(row['title']),
      phone: _optionalString(row['phone']),
      email: _optionalString(row['email']).isNotEmpty
          ? _optionalString(row['email'])
          : (sessionEmail ?? ''),
      avatarStoragePath: _optionalString(row['avatar_url']),
    );
  }

  String _optionalString(Object? value) {
    return value is String ? value.trim() : '';
  }

  @override
  Future<MyProfileSettings> loadMyProfile() async {
    final profileId = _requireProfileId();
    try {
      final row = await _client
          .from(table)
          .select(
            'display_name, first_name, last_name, title, phone, email, avatar_url',
          )
          .eq('id', profileId)
          .maybeSingle();
      if (row == null) {
        throw const ProfileSettingsRepositoryException(
          ProfileSettingsFailure.notFound,
          'Profil bulunamadı.',
        );
      }
      return _mapProfileRow(row);
    } on ProfileSettingsRepositoryException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ProfileSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e),
      );
    } catch (_) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.unknown,
        'Profil yüklenemedi.',
      );
    }
  }

  @override
  Future<void> updateMyProfile(MyProfileSettings profile) async {
    final profileId = _requireProfileId();
    final displayName = profile.displayName.trim();
    if (displayName.isEmpty) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.validation,
        'Görünen kullanıcı adı boş olamaz.',
      );
    }

    try {
      await _client.from(table).update({
        'display_name': displayName,
        'first_name': profile.firstName.trim(),
        'last_name': profile.lastName.trim(),
        'title': profile.title.trim(),
        'phone': profile.phone.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', profileId);
    } on PostgrestException catch (e) {
      throw ProfileSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e),
      );
    } catch (_) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.unknown,
        'Profil kaydedilemedi.',
      );
    }
  }

  @override
  Future<void> updateAvatarStoragePath(String storagePath) async {
    final profileId = _requireProfileId();
    final trimmed = storagePath.trim();
    if (trimmed.isEmpty) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.validation,
        'Görsel yolu geçersiz.',
      );
    }

    try {
      await _client.from(table).update({
        'avatar_url': trimmed,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', profileId);
    } on PostgrestException catch (e) {
      throw ProfileSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e),
      );
    } catch (_) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.unknown,
        'Profil fotoğrafı kaydedilemedi.',
      );
    }
  }

  Future<Map<String, dynamic>?> _loadPreferencesJson(String profileId) async {
    final row = await _client
        .from(table)
        .select('preferences_json')
        .eq('id', profileId)
        .maybeSingle();
    if (row == null) return null;
    final raw = row['preferences_json'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  @override
  Future<UserDisplayPreferences?> loadMyDisplayPreferences() async {
    final profileId = _requireProfileId();
    try {
      final json = await _loadPreferencesJson(profileId);
      return UserDisplayPreferencesMapper.fromProfilePreferencesJson(json);
    } on ProfileSettingsRepositoryException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ProfileSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e),
      );
    } catch (_) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.unknown,
        'Görünüm tercihleri yüklenemedi.',
      );
    }
  }

  @override
  Future<void> updateMyDisplayPreferences(
    UserDisplayPreferences preferences,
  ) async {
    final profileId = _requireProfileId();
    try {
      final existing = await _loadPreferencesJson(profileId);
      final merged = UserDisplayPreferencesMapper.mergeIntoProfilePreferences(
        existing,
        preferences,
      );
      await _client.from(table).update({
        'preferences_json': merged,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', profileId);
    } on PostgrestException catch (e) {
      throw ProfileSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e),
      );
    } catch (_) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.unknown,
        'Görünüm tercihleri kaydedilemedi.',
      );
    }
  }

  @override
  Future<void> updateMyDisplayName(String displayName) async {
    final profileId = _requireProfileId();
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.validation,
        'Görünen kullanıcı adı boş olamaz.',
      );
    }

    try {
      await _client.from(table).update({
        'display_name': trimmed,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', profileId);
    } on PostgrestException catch (e) {
      throw ProfileSettingsRepositoryException(
        _mapPostgrest(e),
        _safeMessage(e),
      );
    } catch (_) {
      throw const ProfileSettingsRepositoryException(
        ProfileSettingsFailure.unknown,
        'Profil kaydedilemedi.',
      );
    }
  }

  ProfileSettingsFailure _mapPostgrest(PostgrestException e) {
    final code = e.code ?? '';
    if (code == '42501' || code == 'PGRST301') {
      return ProfileSettingsFailure.forbidden;
    }
    if (code == 'PGRST116') {
      return ProfileSettingsFailure.notFound;
    }
    return ProfileSettingsFailure.unknown;
  }

  String _safeMessage(PostgrestException e) {
    final failure = _mapPostgrest(e);
    switch (failure) {
      case ProfileSettingsFailure.forbidden:
        return 'Bu işlem için yetkiniz yok.';
      case ProfileSettingsFailure.notFound:
        return 'Profil bulunamadı.';
      default:
        return 'Profil kaydedilemedi. Lütfen tekrar deneyin.';
    }
  }
}
