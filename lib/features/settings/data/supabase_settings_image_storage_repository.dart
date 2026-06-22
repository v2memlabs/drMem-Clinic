import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import 'settings_image_storage_repository.dart';

class SupabaseSettingsImageStorageRepository implements SettingsImageStorageRepository {
  SupabaseSettingsImageStorageRepository(this._client);

  factory SupabaseSettingsImageStorageRepository.fromSupabase() {
    return SupabaseSettingsImageStorageRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const SettingsImageStorageException(
        'Depolama yapılandırması hazır değil.',
      );
    }
  }

  @override
  Future<void> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String mimeType,
    bool upsert = true,
  }) async {
    _ensureConfigured();
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: upsert,
            ),
          );
    } on StorageException catch (e) {
      final message = e.message?.trim();
      throw SettingsImageStorageException(
        message != null && message.isNotEmpty
            ? message
            : 'Görsel güvenli alana yüklenemedi.',
      );
    } catch (_) {
      throw const SettingsImageStorageException(
        'Görsel güvenli alana yüklenemedi.',
      );
    }
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = SettingsImageStorageRepository.signedUrlExpiresInSeconds,
  }) async {
    _ensureConfigured();
    try {
      return await _client.storage.from(bucket).createSignedUrl(
            path,
            expiresInSeconds,
          );
    } catch (_) {
      throw const SettingsImageStorageException('Önizleme bağlantısı oluşturulamadı.');
    }
  }

  @override
  Future<Uint8List?> downloadBytes({
    required String bucket,
    required String path,
  }) async {
    _ensureConfigured();
    try {
      return await _client.storage.from(bucket).download(path);
    } catch (_) {
      return null;
    }
  }
}
