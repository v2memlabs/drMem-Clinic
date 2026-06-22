/// Private storage path — PII path segment içermez.
///
/// Bucket: `patient-files-private` (Supabase Storage, ileride).
/// Signed URL bu pakette üretilmez.
abstract final class PatientFileStoragePathBuilder {
  static const String defaultBucket = 'patient-files-private';

  /// `tenants/{tenantId}/patients/{patientId}/files/{fileId}/{safeSegment}`
  static String patientUploadPath({
    required String tenantId,
    required String patientId,
    required String fileId,
    String safeSegment = 'file',
  }) {
    return 'tenants/${_seg(tenantId)}/patients/${_seg(patientId)}/files/${_seg(fileId)}/${_safeFilename(safeSegment)}';
  }

  /// `tenants/{tenantId}/patients/{patientId}/pdf/{fileId}/document.pdf`
  static String generatedPdfPath({
    required String tenantId,
    required String patientId,
    required String fileId,
  }) {
    return 'tenants/${_seg(tenantId)}/patients/${_seg(patientId)}/pdf/${_seg(fileId)}/document.pdf';
  }

  static String _seg(String value) {
    final t = value.trim();
    if (t.isEmpty) throw ArgumentError('storage path segment empty');
    return t.replaceAll('/', '_');
  }

  /// Path'te orijinal dosya adı/TC/hasta adı kullanılmaz.
  static String _safeFilename(String original) {
    var base = original.trim().toLowerCase();
    if (base.isEmpty) return 'file';
    if (base.contains('..')) {
      base = base.replaceAll('..', '');
    }
    base = base.replaceAll(RegExp(r'[/\\]'), '_');
    final sanitized = base.replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    if (sanitized.isEmpty) return 'file';
    if (sanitized.length > 80) return sanitized.substring(0, 80);
    return sanitized;
  }
}
