import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/backend_config.dart';
import 'supabase_env_config.dart';

/// Supabase client init sonucu.
enum SupabaseInitStatus {
  notConfigured,
  skippedMockBackend,
  initialized,
  failed,
}

class SupabaseInitResult {
  final SupabaseInitStatus status;
  final String? errorMessage;

  const SupabaseInitResult(this.status, {this.errorMessage});

  bool get success => status == SupabaseInitStatus.initialized;
}

/// Yalnızca anon key ile client init — service_role yok.
abstract final class SupabaseClientInitializer {
  static Future<SupabaseInitResult> initializeIfConfigured() async {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      if (!SupabaseEnvConfig.isSupabaseConfigured) {
        return const SupabaseInitResult(SupabaseInitStatus.notConfigured);
      }
      return const SupabaseInitResult(SupabaseInitStatus.skippedMockBackend);
    }

    try {
      await Supabase.initialize(
        url: SupabaseEnvConfig.supabaseUrl,
        anonKey: SupabaseEnvConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      return const SupabaseInitResult(SupabaseInitStatus.initialized);
    } catch (e) {
      return SupabaseInitResult(
        SupabaseInitStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  static bool get isInitialized {
    if (!SupabaseEnvConfig.isSupabaseConfigured) return false;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }
}
