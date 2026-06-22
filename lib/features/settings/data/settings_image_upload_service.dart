import 'dart:typed_data';

import '../../../core/auth/auth_session.dart';
import '../../../core/session/active_tenant_context_store.dart';
import 'profile_settings_repository.dart';
import 'profile_settings_repository_provider.dart';
import 'settings_image_storage_availability.dart';
import 'settings_image_storage_path_builder.dart';
import 'settings_image_storage_repository.dart';
import 'settings_image_storage_repository_provider.dart';
import 'settings_image_storage_user_messages.dart';
import 'tenant_settings_repository.dart';
import 'tenant_settings_repository_provider.dart';

enum SettingsImageKind {
  profileAvatar,
  clinicLogo,
  clinicBanner,
}

class SettingsImageUploadException implements Exception {
  const SettingsImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class SettingsImageUploadService {
  static const int maxAvatarBytes = 2 * 1024 * 1024;
  static const int maxBrandingBytes = 5 * 1024 * 1024;

  static const Set<String> allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static Future<String> upload({
    required SettingsImageKind kind,
    required Uint8List bytes,
    required String mimeType,
    required String originalFileName,
  }) async {
    if (!SettingsImageStorageAvailability.isOperational) {
      throw const SettingsImageUploadException(
        SettingsImageStorageUserMessages.notConfigured,
      );
    }

    final ctx = ActiveTenantContextStore.current;
    if (ctx == null) {
      throw const SettingsImageUploadException('Aktif klinik bulunamadı.');
    }

    final normalizedMime = mimeType.trim().toLowerCase();
    if (!allowedMimeTypes.contains(normalizedMime)) {
      throw const SettingsImageUploadException(
        'Yalnızca JPEG, PNG veya WebP yüklenebilir.',
      );
    }

    final maxBytes = kind == SettingsImageKind.profileAvatar
        ? maxAvatarBytes
        : maxBrandingBytes;
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const SettingsImageUploadException(
        'Dosya boyutu geçersiz veya izin verilen sınırı aşıyor.',
      );
    }

    if (kind == SettingsImageKind.clinicLogo ||
        kind == SettingsImageKind.clinicBanner) {
      if (!AuthSession.canEditClinicProfile) {
        throw const SettingsImageUploadException(
          'Klinik görsellerini yalnızca doktor hesabı güncelleyebilir.',
        );
      }
    }

    final ext = SettingsImageStoragePathBuilder.extensionFromMime(normalizedMime);
    final tenantId = ctx.tenantId;
    final profileId = ctx.profile.userId;

    final path = switch (kind) {
      SettingsImageKind.profileAvatar => SettingsImageStoragePathBuilder.avatarPath(
          tenantId: tenantId,
          profileId: profileId,
          extension: ext,
        ),
      SettingsImageKind.clinicLogo => SettingsImageStoragePathBuilder.logoPath(
          tenantId: tenantId,
          extension: ext,
        ),
      SettingsImageKind.clinicBanner => SettingsImageStoragePathBuilder.bannerPath(
          tenantId: tenantId,
          extension: ext,
        ),
    };

    const bucket = SettingsImageStoragePathBuilder.defaultBucket;
    final storage = SettingsImageStorageRepositoryProvider.repository;

    try {
      await storage.upload(
        bucket: bucket,
        path: path,
        bytes: bytes,
        mimeType: normalizedMime,
        upsert: true,
      );
    } on SettingsImageStorageException catch (e) {
      throw SettingsImageUploadException(e.message);
    }

    try {
      switch (kind) {
        case SettingsImageKind.profileAvatar:
          await ProfileSettingsRepositoryProvider.repository
              .updateAvatarStoragePath(path);
        case SettingsImageKind.clinicLogo:
          await TenantSettingsRepositoryProvider.repository
              .updateBrandingPaths(logoStoragePath: path);
        case SettingsImageKind.clinicBanner:
          await TenantSettingsRepositoryProvider.repository
              .updateBrandingPaths(bannerStoragePath: path);
      }
    } on ProfileSettingsRepositoryException catch (e) {
      throw SettingsImageUploadException(e.message);
    } on TenantSettingsRepositoryException catch (e) {
      throw SettingsImageUploadException(e.message);
    }

    return path;
  }

  static Future<Uint8List?> loadPreviewBytes(String? storagePath) async {
    final path = storagePath?.trim();
    if (path == null || path.isEmpty) return null;

    final storage = SettingsImageStorageRepositoryProvider.repository;
    try {
      return await storage.downloadBytes(
        bucket: SettingsImageStoragePathBuilder.defaultBucket,
        path: path,
      );
    } on SettingsImageStorageException {
      return null;
    }
  }

  static Future<String?> signedPreviewUrl(String? storagePath) async {
    final path = storagePath?.trim();
    if (path == null || path.isEmpty) return null;

    final storage = SettingsImageStorageRepositoryProvider.repository;
    try {
      return await storage.createSignedUrl(
        bucket: SettingsImageStoragePathBuilder.defaultBucket,
        path: path,
      );
    } on SettingsImageStorageException {
      return null;
    }
  }
}
