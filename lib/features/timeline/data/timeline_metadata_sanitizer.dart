/// Timeline `metadata` jsonb — yasak hassas anahtarları ayıklar.
abstract final class TimelineMetadataSanitizer {
  static const Set<String> _forbiddenKeys = {
    'internal_doctor_note',
    'internaldoctornote',
    'clinical_data',
    'clinicaldata',
    'rawclinicaldata',
    'file_content',
    'filecontent',
    'pdf_content',
    'pdfcontent',
    'storage_path',
    'storagepath',
    'storage_bucket',
    'storagebucket',
    'signed_url',
    'signedurl',
    'public_url',
    'publicurl',
    'access_token',
    'accesstoken',
    'service_role',
    'servicerole',
    'secret',
    'token',
    'jwt',
    'sql',
    'stack_trace',
    'stacktrace',
    'raw_exception',
    'rawexception',
    'postgrest',
    'anamnesis',
    'physical_exam',
    'doctor_private_note',
    'private_note',
    'description',
    'notes',
  };

  static Map<String, Object?> sanitize(Map<String, Object?> input) {
    final out = <String, Object?>{};
    for (final entry in input.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      if (_isForbidden(key)) continue;
      final value = entry.value;
      if (value is Map || value is List) continue;
      if (value is String && value.length > 500) continue;
      out[key] = value;
    }
    return out;
  }

  static bool _isForbidden(String key) {
    final lower = key.toLowerCase().replaceAll('-', '_');
    if (_forbiddenKeys.contains(lower)) return true;
    if (lower.contains('internal') && lower.contains('note')) return true;
    if (lower.contains('clinical') && lower.contains('data')) return true;
    if (lower.contains('storage') && lower.contains('path')) return true;
    if (lower.contains('signed') && lower.contains('url')) return true;
    return false;
  }
}
