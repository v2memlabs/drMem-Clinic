/// Supabase ortam değişkenleri — yalnızca [supabaseAnonKey] (client).
///
/// **service_role** istemcide kullanılmaz; bu sınıfta alan yoktur.
abstract final class SupabaseEnvConfig {
  static String supabaseUrl = '';
  static String supabaseAnonKey = '';

  static void loadFromEnvironment() {
    supabaseUrl = const String.fromEnvironment('SUPABASE_URL').trim();
    supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY').trim();
  }

  /// Debug asset veya test override — yalnızca boş alanları doldurur.
  static void applyOverrides(Map<String, dynamic> raw) {
    final url = _stringValue(raw['SUPABASE_URL']);
    if (url != null && supabaseUrl.isEmpty) {
      supabaseUrl = url;
    }
    final key = _stringValue(raw['SUPABASE_ANON_KEY']);
    if (key != null && supabaseAnonKey.isEmpty) {
      supabaseAnonKey = key;
    }
  }

  static String? _stringValue(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// URL ve anon key doluysa Supabase modu teknik olarak yapılandırılmış sayılır.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
