/// Metadata JSONB — yasak hassas anahtarları ayıklar.
abstract final class PatientFileMetadataSanitizer {
  static const Set<String> _forbiddenKeys = {
    'internal_doctor_note',
    'internaldoctornote',
    'clinical_data',
    'clinicaldata',
    'rawclinicaldata',
    'anamnesis',
    'physical_exam',
    'physicalexam',
    'chiefcomplaint',
    'clinicalimpression',
    'file_content',
    'filecontent',
    'pdf_content',
    'pdfcontent',
    'raw_clinical_data',
    'signed_url',
    'signedurl',
    'public_url',
    'publicurl',
    'access_token',
    'accesstoken',
    'jwt',
    'service_role',
    'servicerole',
    'secret',
    'token',
    'stack_trace',
    'stacktrace',
    'sql',
    'postgrest',
  };

  static Map<String, Object?> sanitize(Map<String, Object?> input) {
    final out = <String, Object?>{};
    for (final entry in input.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      if (_isForbidden(key)) continue;
      final value = entry.value;
      if (value is Map || value is List) continue;
      if (value is String && value.length > 2000) continue;
      out[key] = value;
    }
    return out;
  }

  static bool _isForbidden(String key) {
    final lower = key.toLowerCase().replaceAll('-', '_');
    if (_forbiddenKeys.contains(lower)) return true;
    if (lower.contains('signed') && lower.contains('url')) return true;
    if (lower.contains('internal') && lower.contains('note')) return true;
    if (lower.contains('clinical') && lower.contains('data')) return true;
    return false;
  }
}
