import 'supabase_env_config.dart';

/// Supabase client init sonucu (gerçek [supabase_flutter] yok — Paket 6).
enum SupabaseInitStatus {
  notConfigured,
  skippedMockBackend,
  notImplemented,
}

class SupabaseInitResult {
  final SupabaseInitStatus status;

  const SupabaseInitResult(this.status);

  bool get success => status == SupabaseInitStatus.notImplemented;
}

/// Pasif initializer — [main] mock modda çağırmaz veya no-op.
abstract final class SupabaseClientInitializer {
  static Future<SupabaseInitResult> initializeIfConfigured() async {
    if (!SupabaseEnvConfig.isSupabaseConfigured) {
      return const SupabaseInitResult(SupabaseInitStatus.notConfigured);
    }
    return const SupabaseInitResult(SupabaseInitStatus.notImplemented);
  }
}
