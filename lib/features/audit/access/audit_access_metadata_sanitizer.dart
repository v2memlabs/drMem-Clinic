/// Audit metadata — yasak anahtarları ve ham klinik içeriği ayıklar.
abstract final class AuditAccessMetadataSanitizer {
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
    'preliminarydiagnosis',
    'finaldiagnosis',
    'doctor_private_note',
    'doctorprivatenote',
    'privatenote',
    'pdf_content',
    'file_content',
    'access_token',
    'jwt',
    'service_role',
    'stack_trace',
    'sql',
    'postgrest',
  };

  static const Set<String> _allowedKeys = {
    'result_count',
    'filtered_by_patient',
    'includes_internal_note_access',
    'attempted_event_type',
    'correlation_id',
    'platform',
    'success',
    'failure_category',
    'source',
    'actor_role',
    'actor_user_id',
    'tenant_id',
  };

  static Map<String, Object?> sanitize(Map<String, Object?> input) {
    final out = <String, Object?>{};
    for (final entry in input.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      if (_isForbidden(key)) continue;
      if (!_allowedKeys.contains(key.toLowerCase()) &&
          _looksLikeSensitiveKey(key)) {
        continue;
      }
      final value = entry.value;
      if (value is String && value.length > 500) continue;
      if (value is Map || value is List) continue;
      out[key] = value;
    }
    return out;
  }

  static bool _isForbidden(String key) {
    final lower = key.toLowerCase().replaceAll('-', '_');
    if (_forbiddenKeys.contains(lower)) return true;
    for (final forbidden in _forbiddenKeys) {
      if (lower.contains(forbidden)) return true;
    }
    return false;
  }

  static bool _looksLikeSensitiveKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('note') &&
            lower.contains('internal') ||
        lower.contains('clinical') && lower.contains('data') ||
        lower.contains('password') ||
        lower.contains('secret');
  }

  static Map<String, Object?> buildBase({
    required bool success,
    String? failureCategory,
    required String source,
    String? actorRole,
    String? actorUserId,
    String? tenantId,
    int? resultCount,
    bool? filteredByPatient,
  }) {
    return sanitize({
      'success': success,
      if (failureCategory != null) 'failure_category': failureCategory,
      'source': source,
      if (actorRole != null) 'actor_role': actorRole,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (resultCount != null) 'result_count': resultCount,
      if (filteredByPatient != null) 'filtered_by_patient': filteredByPatient,
    });
  }
}
