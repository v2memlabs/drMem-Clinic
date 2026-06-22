/// Private branding/avatar storage paths — bucket `clinic-branding-private`.
abstract final class SettingsImageStoragePathBuilder {
  static const String defaultBucket = 'clinic-branding-private';

  static String avatarPath({
    required String tenantId,
    required String profileId,
    required String extension,
  }) {
    return 'tenants/${_seg(tenantId)}/profiles/${_seg(profileId)}/avatar.${_ext(extension)}';
  }

  static String logoPath({
    required String tenantId,
    required String extension,
  }) {
    return 'tenants/${_seg(tenantId)}/branding/logo.${_ext(extension)}';
  }

  static String bannerPath({
    required String tenantId,
    required String extension,
  }) {
    return 'tenants/${_seg(tenantId)}/branding/banner.${_ext(extension)}';
  }

  static String extensionFromMime(String mimeType) {
    switch (mimeType.trim().toLowerCase()) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }

  static String extensionFromFileName(String fileName) {
    final lower = fileName.trim().toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  static String mimeFromFileName(String fileName) {
    final ext = extensionFromFileName(fileName);
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static String _seg(String value) {
    final t = value.trim();
    if (t.isEmpty) throw ArgumentError('storage path segment empty');
    return t.replaceAll('/', '_');
  }

  static String _ext(String extension) {
    final e = extension.trim().toLowerCase();
    if (e == 'jpeg') return 'jpg';
    if (e == 'png' || e == 'webp' || e == 'jpg') return e;
    return 'jpg';
  }
}
