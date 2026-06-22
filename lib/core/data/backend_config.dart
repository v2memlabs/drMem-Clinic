import '../config/supabase_env_config.dart';
import 'data_backend.dart';

/// Uygulama backend stratejisi — varsayılan mock.
///
/// `DATA_BACKEND=supabase` + boş URL/key → güvenli şekilde mock’a düşer (crash yok).
abstract final class AppBackendConfig {
  /// Dart-define ile istenen backend (yapılandırma eksikse mock’a düşebilir).
  static DataBackend requestedBackend = DataBackend.mock;

  /// Etkin backend — repository/registry ve login modu bunu kullanır.
  static DataBackend activeBackend = DataBackend.mock;

  static String? _runtimeDataBackendOverride;

  static void applyEnvironment() {
    final fromDefine = const String.fromEnvironment('DATA_BACKEND').trim();
    final rawBackend = fromDefine.isNotEmpty
        ? fromDefine
        : (_runtimeDataBackendOverride ?? 'mock');
    requestedBackend = _parseBackend(rawBackend);
    activeBackend = _resolveActiveBackend(requestedBackend);
  }

  /// Debug asset — DATA_BACKEND yalnızca dart-define yokken override edilir.
  static void applyRuntimeBackendOverride(Map<String, dynamic> raw) {
    if (const String.fromEnvironment('DATA_BACKEND').trim().isNotEmpty) {
      _runtimeDataBackendOverride = null;
      return;
    }
    _runtimeDataBackendOverride = _stringValue(raw['DATA_BACKEND']);
  }

  static String? _stringValue(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DataBackend _resolveActiveBackend(DataBackend requested) {
    if (requested == DataBackend.supabase && !SupabaseEnvConfig.isSupabaseConfigured) {
      return DataBackend.mock;
    }
    return requested;
  }

  static DataBackend _parseBackend(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'supabase':
        return DataBackend.supabase;
      case 'mock':
      default:
        return DataBackend.mock;
    }
  }

  static bool get isMock => activeBackend == DataBackend.mock;

  static bool get isSupabase => activeBackend == DataBackend.supabase;

  static bool get isSupabaseConfigured => SupabaseEnvConfig.isSupabaseConfigured;

  /// Supabase istendi ama URL/key yok — kullanıcı mock UI görür.
  static bool get isSupabaseRequestedButNotConfigured =>
      requestedBackend == DataBackend.supabase &&
      !SupabaseEnvConfig.isSupabaseConfigured;

  static const String strategyLabel = 'Uzak veritabanı (PostgreSQL)';
}
