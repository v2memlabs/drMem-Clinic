import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import 'patient_file_storage_repository.dart';

class SupabasePatientFileStorageRepository implements PatientFileStorageRepository {
  SupabasePatientFileStorageRepository(this._client);

  factory SupabasePatientFileStorageRepository.fromSupabase() {
    return SupabasePatientFileStorageRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PatientFileStorageException(
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
    bool upsert = false,
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
    } catch (_) {
      throw const PatientFileStorageException('Dosya güvenli alana yüklenemedi.');
    }
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = PatientFileStorageRepository.signedUrlExpiresInSeconds,
  }) async {
    _ensureConfigured();
    try {
      final url = await _client.storage.from(bucket).createSignedUrl(
            path,
            expiresInSeconds,
          );
      return url;
    } catch (_) {
      throw const PatientFileStorageException(
        'Geçici bağlantı oluşturulamadı.',
      );
    }
  }

  @override
  Future<void> remove({
    required String bucket,
    required String path,
  }) async {
    _ensureConfigured();
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (_) {
      // Rollback best-effort — sessiz.
    }
  }

  @override
  Future<Uint8List> download({
    required String bucket,
    required String path,
  }) async {
    _ensureConfigured();
    try {
      return await _client.storage.from(bucket).download(path);
    } catch (_) {
      throw const PatientFileStorageException('Dosya indirilemedi.');
    }
  }
}
