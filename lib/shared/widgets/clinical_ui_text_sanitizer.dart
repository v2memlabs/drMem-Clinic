/// Klinik UI metinleri — yasak teknik terim listesi ve sanitize.
abstract final class ClinicalUiTextSanitizer {
  static const forbiddenUiTokens = <String>[
    'Supabase',
    'PostgREST',
    'PostgrestException',
    'AuthException',
    'StorageException',
    'RLS',
    'JWT',
    'tenant_id',
    'profile_id',
    'auth_user_id',
    'storage_path',
    'storage_bucket',
    'signed_url',
    'public_url',
    'exception',
    'stack trace',
    'stackTrace',
    'debug',
    'internalDoctorNote',
    'internal_doctor_note',
    'raw clinical_data',
    'clinical_data',
    'service_role',
    'secret',
    'token',
  ];

  static bool containsForbiddenToken(String input) {
    final lower = input.toLowerCase();
    for (final token in forbiddenUiTokens) {
      if (lower.contains(token.toLowerCase())) {
        return true;
      }
    }
    if (RegExp(
      r'\bException\b|Error:|StackTrace|PostgREST|PostgrestException',
      caseSensitive: false,
    ).hasMatch(input)) {
      return true;
    }
    return false;
  }

  static String sanitize(String input) {
    var out = input;
    for (final token in forbiddenUiTokens) {
      out = out.replaceAll(
        RegExp(RegExp.escape(token), caseSensitive: false),
        '',
      );
    }
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    return out.isEmpty ? '—' : out;
  }
}
